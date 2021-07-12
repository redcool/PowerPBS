#if !defined(SIMPLE_PBS_FORWARD_CGINC)
#define SIMPLE_PBS_FORWARD_CGINC

#include "UnityCG.cginc"
#include "UnityStandardutils.cginc"
// #include "UnityPBSLighting.cginc"
#include "UnityStandardBRDF.cginc"
#include "PowerPBSCore.cginc"
#include "PowerPBSHair.cginc"
#include "PowerPBSUrpShadows.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal:NORMAL;
    float4 tangent:TANGENT;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    UNITY_FOG_COORDS(1)
    float4 pos : SV_POSITION;
    float4 tSpace0:TEXCOORD2;
    float4 tSpace1:TEXCOORD3;
    float4 tSpace2:TEXCOORD4;
    float3 viewTangentSpace:TEXCOORD5;
    SHADOW_COORDS(6)
    // UNITY_LIGHTING_COORDS(6,7)
};

//-------------------------------------
v2f vert (appdata v)
{
    v2f o = (v2f)0;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);

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
    return o;
}

float4 frag (v2f i) : SV_Target
{

    // heightClothSSSMask
    float4 heightClothSSSMask = UNITY_SAMPLE_TEX2D(_HeightClothSSSMask,i.uv);
    float height = heightClothSSSMask.r;
    float clothMask = heightClothSSSMask.g;
    float frontSSS = heightClothSSSMask.b;
    float backSSS = heightClothSSSMask.a;

    float2 uv = Parallax(i.uv,height,i.viewTangentSpace);

    // metallicSmoothnessOcclusion
    float4 metallicSmoothnessOcclusion = UNITY_SAMPLE_TEX2D(_MetallicMap ,uv);
    float metallic = metallicSmoothnessOcclusion.r * _Metallic;
    float smoothness = metallicSmoothnessOcclusion.g * _Smoothness;
    float occlusion = lerp(1,metallicSmoothnessOcclusion.b , _Occlusion);
    
    float roughness = 1.0 - smoothness;
    // roughness = roughness * roughness;

    float detailMask=0;
    float4 mainTex = CalcAlbedo(uv,detailMask/*out*/);
    float3 albedo = mainTex.rgb;
    albedo.rgb *= occlusion;
    float alpha = mainTex.a;

    if(_AlphaTestOn)
        clip(alpha - _Cutoff);

    float3 tn = CalcNormal(uv,detailMask);
    float3 n = normalize(float3(
        dot(i.tSpace0.xyz,tn),
        dot(i.tSpace1.xyz,tn),
        dot(i.tSpace2.xyz,tn)
    ));
    float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
    float3 v = normalize(GetWorldViewDir(worldPos));
    float3 r = reflect(-v,n) + _ReflectionOffsetDir;

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

    UnityIndirect indirect = CalcGI(albedo,uv,r,n,occlusion,roughness);    
    half oneMinusReflectivity;
    half3 specColor;
    albedo = DiffuseAndSpecularFromMetallic (albedo, metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

    half outputAlpha;
    albedo = AlphaPreMultiply (albedo, alpha, oneMinusReflectivity, /*out*/ outputAlpha);

    // half4 c = UNITY_BRDF_PBS (albedo, specColor, oneMinusReflectivity, smoothness, n, v, light, indirect);
    PBSData data = (PBSData)0;
    data.tangent = tangent;
    data.binormal = binormal;
    data.clothMask = 1;
    data.isClothOn = _ClothOn;
    data.isHairOn = _HairOn;

    if(_ClothMaskOn){
        data.clothMask = clothMask;
    }

    if(_HairOn){
		float hairAo;
        data.hairSpecColor = CalcHairSpecColor(i.uv,tangent,n,binormal,light.dir,v, hairAo);
		albedo *= lerp(1, hairAo, _HairAoIntensity);
    }
float outputNL;
    half4 c = CalcPBS(albedo, specColor, oneMinusReflectivity, smoothness, n, v, light, indirect,data/**/);
    c.a = outputAlpha;

    if(_ScatteringLUTOn){
        c.rgb += PreScattering(worldNormal,light,data.nl,mainTex,worldPos,_CurvatureScale,_ScatteringIntensity);
    }
    c.rgb += CalcEmission(albedo,uv);

    if(_SSSOn){
        c.rgb += CalcSSS(uv,light.dir,v,frontSSS,backSSS);
    }
    // apply fog
    UNITY_APPLY_FOG(i.fogCoord, c);
    return c;
}

#endif // SIMPLE_PBS_FORWARD_CGINC