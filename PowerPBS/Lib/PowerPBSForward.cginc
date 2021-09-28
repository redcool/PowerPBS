#if !defined(POWER_PBS_FORWARD_CGINC)
#define POWER_PBS_FORWARD_CGINC

#include "UnityCG.cginc"
#include "UnityStandardutils.cginc"
#include "UnityStandardBRDF.cginc"
#include "PowerPBSCore.cginc"
#include "PowerPBSHair.cginc"
#include "PowerPBSUrpShadows.cginc"
#include "Blur.cginc"
#include "ParallaxMapping.hlsl"

struct appdata
{
    float4 vertex : POSITION;
    float4 color:COLOR;
    float2 uv : TEXCOORD0;
    float3 normal:NORMAL;
    float4 tangent:TANGENT;
};

struct v2f
{
    float4 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 pos : SV_POSITION;
    float4 tSpace0:TEXCOORD2;
    float4 tSpace1:TEXCOORD3;
    float4 tSpace2:TEXCOORD4;
    float3 viewTangentSpace:TEXCOORD5;
    SHADOW_COORDS(6)
    float4 screenPos:TEXCOORD7;
};

//-------------------------------------
v2f vert (appdata v)
{
    v2f o = (v2f)0;
    ApplyVertexWave(v.vertex/**/,v.normal,v.color);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = float4(TRANSFORM_TEX(v.uv, _MainTex),v.uv);

    float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
    float3 n = UnityObjectToWorldNormal(v.normal);
    float3 t = UnityObjectToWorldDir(v.tangent.xyz);
    float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    float3 b = cross(n,t) * tangentSign;
    o.tSpace0 = float4(t.x,b.x,n.x,worldPos.x);
    o.tSpace1 = float4(t.y,b.y,n.y,worldPos.y);
    o.tSpace2 = float4(t.z,b.z,n.z,worldPos.z);

    if(_ParallalOn){
        float3 viewWorldSpace = UnityWorldSpaceViewDir(worldPos);
        float3x3 tSpace = float3x3(o.tSpace0.xyz,o.tSpace1.xyz,o.tSpace2.xyz);
        o.viewTangentSpace = mul(viewWorldSpace,tSpace);
    }
    //UNITY_TRANSFER_LIGHTING(o,v.uv.xy);
    TRANSFER_SHADOW(o)
    UNITY_TRANSFER_FOG(o,o.pos);
    o.screenPos = ComputeScreenPos(o.pos);
    return o;
}

float4 frag (v2f i) : SV_Target
{

    // heightClothSSSMask
    float4 heightClothSSSMask = SAMPLE_TEXTURE2D(_HeightClothSSSMask,sampler_linear_repeat,i.uv.zw);
    float height = heightClothSSSMask.x;
    float clothMask = heightClothSSSMask.y;
    // float frontSSS = heightClothSSSMask.z;
    // float backSSS = heightClothSSSMask.w;

    float2 uv = i.uv.xy;
    if(_ParallalOn){
        uv += ParallaxMapOffset(_HeightScale,i.viewTangentSpace,height);
    }

    // pbrMask
    float4 pbrMask = SAMPLE_TEXTURE2D(_MetallicMap,sampler_MetallicMap ,uv);
    float metallic = pbrMask[_MetallicChannel] * _Metallic;
    float smoothness = pbrMask[_SmoothnessChannel] * _Smoothness;
    float occlusion = lerp(1,pbrMask[_OcclusionChannel] , _Occlusion);
    
    float detailMask=0;
    float4 mainTex = CalcAlbedo(uv,detailMask/*out*/);
    mainTex *= _Color;

    float3 albedo = mainTex.rgb;
    // albedo.rgb *= occlusion; // more dark than urp'lit
    float alpha = _AlphaFrom == ALPHA_FROM_MAIN_TEX ? mainTex.a : pbrMask.a * _Color.a;

    if(_AlphaTestOn)
        clip(alpha - _Cutoff);

    float2 normalMapUV = TRANSFORM_TEX(uv, _NormalMap);
    float3 tn = CalcNormal(normalMapUV,detailMask);
    float3 n = normalize(float3(
        dot(i.tSpace0.xyz,tn),
        dot(i.tSpace1.xyz,tn),
        dot(i.tSpace2.xyz,tn)
    ));
    float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
    float3 v = normalize(GetWorldViewDir(worldPos));
    float3 r = SafeNormalize(reflect(-v + _ReflectionOffsetDir.xyz,n));

    float3 tangent = normalize(float3(i.tSpace0.x,i.tSpace1.x,i.tSpace2.x));
    float3 binormal = normalize(float3(i.tSpace0.y,i.tSpace1.y,i.tSpace2.y));
    float3 worldNormal = normalize(float3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));

    UnityLight light = GetLight();
    float3 lightColorNoAtten = light.color;

    if(_ApplyShadowOn){
        // UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
        half atten = URP_SHADOW_ATTENUATION(i,worldPos);
        light.color *= atten;
    }

    half oneMinusReflectivity;
    half3 specColor = 0;
    albedo = DiffuseAndSpecularFromMetallic (albedo, metallic, /*inout*/ specColor, /*out*/ oneMinusReflectivity);
    // --- specular map 
    if(_CustomSpecularMapOn){
        float2 specUV = TRANSFORM_TEX(i.uv.zw,_CustomSpecularMap);
        float4 customSpecColor = SAMPLE_TEXTURE2D(_CustomSpecularMap,sampler_linear_repeat,specUV);
        specColor = lerp(unity_ColorSpaceDielectricSpec.xyz,customSpecColor.xyz,_Metallic) * customSpecColor.w;
    }

    half outputAlpha;
    albedo = AlphaPreMultiply (albedo, alpha, oneMinusReflectivity, /*out*/ outputAlpha);

    PBSData data = InitPBSData(tangent,binormal,n,v,oneMinusReflectivity, smoothness,heightClothSSSMask,worldPos);
    data.mainTex = mainTex;

    // calc strand specular
    if(_PBRMode == PBR_MODE_STRAND){
        float4 ao_shift_specMask_tbMask = SAMPLE_TEXTURE2D(_StrandMaskTex,sampler_linear_repeat,i.uv);
		float hairAo = ao_shift_specMask_tbMask.x;
        data.hairSpecColor = CalcHairSpecColor(tangent,n,binormal,light.dir,v,ao_shift_specMask_tbMask.yzw);
		albedo *= lerp(1, hairAo, _HairAoIntensity);
    }

    UnityIndirect indirect = CalcGI(albedo,uv,r,n,occlusion,data.perceptualRoughness);
    ClearCoatData coatData = InitCoatData(_CoatSmoothness,_ClearCoatSpecColor * specColor,unity_ColorSpaceDielectricSpec.x);

    coatData.reflectDir = r;
    coatData.occlusion = occlusion;

    half4 c = CalcPBS(albedo, specColor, light, indirect,data/**/,coatData);
    c.a = outputAlpha;

    //for preintegrated lut
    if(_ScatteringLUTOn){
        float3 lightColor = _LightColorNoAtten ? lightColorNoAtten : light.color;
        float3 scatteredColor = PreScattering(worldNormal,light.dir,lightColor,data.nl,mainTex,worldPos,_CurvatureScale,_ScatteringIntensity);
        c.rgb += scatteredColor;
    }
    if(_DiffuseProfileOn){
        // c.rgb += DiffuseProfile(c,TEXTURE2D_ARGS(_MainTex,sampler_MainTex),uv,float2(_MainTex_TexelSize.x,0) * _BlurSize,mainTex.a);
        // c.rgb += DiffuseProfile(c,TEXTURE2D_ARGS(_MainTex,sampler_MainTex),uv,float2(0,_MainTex_TexelSize.y) * _BlurSize,mainTex.a);
        float2 screenUV = i.screenPos.xy/i.screenPos.w;
        float profileMask = _DiffuseProfileMaskUserMainTexA ? mainTex.a : 1;
        c.rgb += DiffuseProfile(c,TEXTURE2D_ARGS(_CameraOpaqueTexture,sampler_linear_repeat),screenUV,float2(_CameraOpaqueTexture_TexelSize.x,0) * _BlurSize,profileMask);
        c.rgb += DiffuseProfile(c,TEXTURE2D_ARGS(_CameraOpaqueTexture,sampler_linear_repeat),screenUV,float2(0,_CameraOpaqueTexture_TexelSize.y) * _BlurSize,profileMask);
        // c = originalColor + horizontalGasussianColor + verticalGausssianColor
        c.rgb /=3;
    }
    //for emission
    if(_EmissionOn){
        c.rgb += CalcEmission(albedo,uv);
    }
    
    if(_SSSOn){
        c.rgb += CalcSSS(light.dir,v,heightClothSSSMask.zw);
    }
    if(_FresnelAlphaOn){
        c.a *= saturate(smoothstep(_FresnelMin,_FresnelMax,data.nv));
    }
    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, c);
    return c;
}


//-------------------------------------
v2f DepthOnlyVertex (appdata v)
{
    v2f o = (v2f)0;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = float4(TRANSFORM_TEX(v.uv, _MainTex),v.uv);
    return o;
}

float4 DepthOnlyFragment (v2f i) : SV_Target
{
    float detailMask = 0;
    float4 mainTex = CalcAlbedo(i.uv.xy,detailMask/*out*/);

    if(_AlphaTestOn)
        clip(mainTex.a - _Cutoff);

    return 0;
}

#endif // POWER_PBS_FORWARD_CGINC