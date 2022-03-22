#if !defined(POWER_PBS_FORWARD_HLSL)
#define POWER_PBS_FORWARD_HLSL

#include "PowerPBSCore.hlsl"
#include "PowerPBSHair.hlsl"
#include "URP_MainLightShadows.hlsl"
#include "Blur.hlsl"
#include "ParallaxMapping.hlsl"

#if defined(_POWER_DEBUG)
#include "PowerPBSDebug.hlsl"
#endif

struct appdata
{
    half4 vertex : POSITION;
    half4 color:COLOR;
    half2 uv : TEXCOORD0;
    half3 normal:NORMAL;
    half4 tangent:TANGENT;
};

struct v2f
{
    half4 uv : TEXCOORD0;
    half4 fogCoord:TEXCOORD1;
    half4 pos : SV_POSITION;
    half4 tSpace0:TEXCOORD2;
    half4 tSpace1:TEXCOORD3;
    half4 tSpace2:TEXCOORD4;
    half3 viewTangentSpace:TEXCOORD5;
    float4 _ShadowCoord:TEXCOORD6;
    half4 screenPos:TEXCOORD7;
};

//-------------------------------------
v2f vert (appdata v)
{
    v2f o = (v2f)0;
    ApplyVertexWave(v.vertex/**/,v.normal,v.color);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = half4(TRANSFORM_TEX(v.uv, _MainTex),v.uv);

    float4 worldPos = mul(unity_ObjectToWorld,v.vertex);
    half3 n = normalize(UnityObjectToWorldNormal(v.normal));
    half3 t = normalize(UnityObjectToWorldDir(v.tangent.xyz));
    t = normalize(t - dot(t,n) * n);
    
    half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    half3 b = cross(n,t) * tangentSign;
    o.tSpace0 = half4(t.x,b.x,n.x,worldPos.x);
    o.tSpace1 = half4(t.y,b.y,n.y,worldPos.y);
    o.tSpace2 = half4(t.z,b.z,n.z,worldPos.z);

    if(_ParallalOn){
        half3 viewWorldSpace = UnityWorldSpaceViewDir(worldPos);
        half3x3 tSpace = half3x3(o.tSpace0.xyz,o.tSpace1.xyz,o.tSpace2.xyz);
        o.viewTangentSpace = mul(viewWorldSpace,tSpace);
    }
    // TRANSFER_SHADOW(o)
    o._ShadowCoord = TransformWorldToShadowCoord(worldPos.xyz);
    o.fogCoord.x = ComputeFogFactor(o.pos.z);
    o.screenPos = ComputeScreenPos(o.pos);
    return o;
}

half4 frag (v2f i) : SV_Target
{
    // heightClothSSSMask
    half4 heightClothSSSMask = SAMPLE_TEXTURE2D(_HeightClothSSSMask,sampler_linear_repeat,i.uv.zw);
    half height = heightClothSSSMask.x;
    half clothMask = heightClothSSSMask.y;
    // half frontSSS = heightClothSSSMask.z;
    // half backSSS = heightClothSSSMask.w;

    half2 uv = i.uv.xy;
    if(_ParallalOn){
        uv += ParallaxMapOffset(_HeightScale,i.viewTangentSpace,height);
    }

    // pbrMask
    half4 pbrMask = SAMPLE_TEXTURE2D(_MetallicMap,sampler_MetallicMap ,uv);
    half metallic = pbrMask[_MetallicChannel] * _Metallic;
    // pbrMask'g is smoothness or roughness ?
    half smoothness = pbrMask[_SmoothnessChannel];
    smoothness = lerp(smoothness , 1 - smoothness,_InvertSmoothnessOn)  * _Smoothness;

    half occlusion = lerp(1,pbrMask[_OcclusionChannel] , _Occlusion);
    
    half detailMask=0;
    half4 mainTex = CalcAlbedo(uv,detailMask/*out*/);
    mainTex *= _Color;

    half3 albedo = mainTex.rgb;
    // albedo.rgb *= occlusion; // more dark than urp'lit
    half alpha = _AlphaFrom == ALPHA_FROM_MAIN_TEX ? mainTex.a : pbrMask.a * _Color.a;

    #if defined(_ALPHA_TEST)
    if(_AlphaTestOn)
        clip(alpha - _Cutoff);
    #endif

    WorldData worldData;
    InitWorldData(uv,detailMask,i.tSpace0,i.tSpace1,i.tSpace2,worldData/**/);

    i._ShadowCoord = TransformWorldToShadowCoord(worldData.pos.xyz);

    UnityLight light = GetLight();
    half3 lightColorNoAtten = light.color;

    if(_ApplyShadowOn){
        // UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
        float atten = CalcShadow(i._ShadowCoord,worldData.pos);
        // return atten;
        light.color *= atten;
    }

    SurfaceData surfaceData;
    InitSurfaceData(i.uv.zw,albedo,alpha,metallic,surfaceData/**/);

    PBSData pbsData;
    InitPBSData(worldData.tangent,worldData.binormal,worldData.normal,worldData.view,surfaceData.oneMinusReflectivity, smoothness,heightClothSSSMask,worldData.pos,pbsData/**/);
    pbsData.mainTex = mainTex;

    // calc strand specular
    #if defined(_PBRMODE_STRANDSPEC)
    if(_PBRMode == PBR_MODE_STRAND){
        half4 ao_shift_specMask_tbMask = SAMPLE_TEXTURE2D(_StrandMaskTex,sampler_linear_repeat,i.uv);
		half hairAo = ao_shift_specMask_tbMask.x;
        pbsData.hairSpecColor = CalcHairSpecColor(worldData.vertexTangent,worldData.normal,worldData.vertexBinormal,light.dir,worldData.view,ao_shift_specMask_tbMask.yzw);
		surfaceData.diffColor *= lerp(1, hairAo, _HairAoIntensity);
    }
    #endif

    UnityIndirect indirect = CalcGI(surfaceData.diffColor,uv,worldData.reflect,worldData.normal,occlusion,pbsData.perceptualRoughness);
    #if defined(_POWER_DEBUG)
        return ShowGI(indirect);
    #endif
    // calc coat data
    ClearCoatData coatData;
    InitCoatData(_CoatSmoothness,_ClearCoatSpecColor * surfaceData.specColor,unity_ColorSpaceDielectricSpec.x,coatData/**/);

    coatData.reflectDir = worldData.reflect;
    coatData.occlusion = occlusion;

    half4 col = CalcPBS(surfaceData.diffColor, surfaceData.specColor, light, indirect,coatData,pbsData/**/);
    col.a = surfaceData.finalAlpha;

    //for preintegrated lut
    #if defined(_PRESSS)
    if(_ScatteringLUTOn){
        half3 lightColor = _LightColorNoAtten ? lightColorNoAtten : light.color;
        half3 scatteredColor = PreScattering(worldData.vertexNormal,light.dir,lightColor,pbsData.nl,mainTex,worldData.pos,_CurvatureScale,_ScatteringIntensity);
        col.rgb += scatteredColor;
    }
    #endif
    
    #if defined(_SSSS)
    // if(_DiffuseProfileOn){
        // col.rgb += DiffuseProfile(col,TEXTURE2D_ARGS(_MainTex,sampler_MainTex),uv,half2(_MainTex_TexelSize.x,0) * _BlurSize,mainTex.a);
        // col.rgb += DiffuseProfile(col,TEXTURE2D_ARGS(_MainTex,sampler_MainTex),uv,half2(0,_MainTex_TexelSize.y) * _BlurSize,mainTex.a);
        half2 screenUV = i.screenPos.xy/i.screenPos.w;
        half profileMask = _DiffuseProfileMaskUserMainTexA ? mainTex.a : 1;
        col.rgb += DiffuseProfile(col,TEXTURE2D_ARGS(_CameraOpaqueTexture,sampler_linear_repeat),screenUV,half2(_CameraOpaqueTexture_TexelSize.x * _BlurSize,0),profileMask);
        col.rgb += DiffuseProfile(col,TEXTURE2D_ARGS(_CameraOpaqueTexture,sampler_linear_repeat),screenUV,half2(0,_CameraOpaqueTexture_TexelSize.y * _BlurSize),profileMask);
        // col = originalColor + horizontalGasussianColor + verticalGausssianColor
        col.rgb *= 0.333;
    // }
    #endif

    if(_SSSOn){
        col.rgb += CalcSSS(light.dir,worldData.view,heightClothSSSMask.zw);
    }

    //for emission
    if(_EmissionOn){
        col.rgb += CalcEmission(surfaceData.diffColor,uv);
    }
    if(_FresnelAlphaOn){
        col.a *= saturate(smoothstep(_FresnelMin,_FresnelMax,pbsData.nv));
    }
    // apply fog
    // UNITY_APPLY_FOG(i.fogCoord, col);
    col.rgb = MixFog(col,i.fogCoord.x);
    return col;
}


//-------------------------------------
v2f DepthOnlyVertex (appdata v)
{
    v2f o = (v2f)0;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = half4(TRANSFORM_TEX(v.uv, _MainTex),v.uv);
    return o;
}

half4 DepthOnlyFragment (v2f i) : SV_Target
{
    #if defined(_ALPHA_TEST)
    if(_AlphaTestOn){
        half detailMask = 0;
        half4 mainTex = CalcAlbedo(i.uv.xy,detailMask/*out*/);
        clip(mainTex.a - _Cutoff);
    }
    #endif
    return 0;
}

#endif // POWER_PBS_FORWARD_HLSL