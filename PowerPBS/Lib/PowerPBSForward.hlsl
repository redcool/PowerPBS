#if !defined(POWER_PBS_FORWARD_HLSL)
#define POWER_PBS_FORWARD_HLSL

#include "PowerPBSCore.hlsl"
#include "Tools/Blur.hlsl"
#include "../../PowerShaderLib/UrpLib/URP_MainLightShadows.hlsl"
#include "../../PowerShaderLib/Lib/ParallaxMapping.hlsl"
#include "../../PowerShaderLib/Lib/FogLib.hlsl"

#if defined(_POWER_DEBUG)
#include "PowerPBSDebug.hlsl"
#endif

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
    float4 fogCoord:TEXCOORD1;
    float4 pos : SV_POSITION;
    float4 tSpace0:TEXCOORD2;
    float4 tSpace1:TEXCOORD3;
    float4 tSpace2:TEXCOORD4;
    float3 viewTangentSpace:TEXCOORD5;
    float4 _ShadowCoord:TEXCOORD6;
    // float4 screenPos:TEXCOORD7;
};

//-------------------------------------
v2f vert (appdata v)
{
    v2f o = (v2f)0;
    
    #if defined(_VERTEX_SCALE_ON)
    ApplyVertexWave(v.vertex/**/,v.normal,v.color);
    #endif

    o.pos = UnityObjectToClipPos(v.vertex.xyz);
    o.uv = float4(TRANSFORM_TEX(v.uv, _MainTex),v.uv);

    float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
    float3 n = (UnityObjectToWorldNormal(v.normal));
    float3 t = (UnityObjectToWorldDir(v.tangent.xyz));
    // t = normalize(t - dot(t,n) * n);
    
    float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    float3 b = cross(n,t) * tangentSign;
    o.tSpace0 = float4(t.x,b.x,n.x,worldPos.x);
    o.tSpace1 = float4(t.y,b.y,n.y,worldPos.y);
    o.tSpace2 = float4(t.z,b.z,n.z,worldPos.z);

    #if defined(_PARALLAX_ON)
    // if(_ParallaxOn)
    {
        float3 viewWorldSpace = UnityWorldSpaceViewDir(worldPos);
        float3x3 tSpace = float3x3(o.tSpace0.xyz,o.tSpace1.xyz,o.tSpace2.xyz);
        o.viewTangentSpace = mul(viewWorldSpace,tSpace);
    }
    #endif
    // TRANSFER_SHADOW(o)
    // o._ShadowCoord = TransformWorldToShadowCoord(worldPos.xyz); // move to frag
    // o.fogCoord.z = ComputeFogFactor(o.pos.z);
    o.fogCoord.xy = CalcFogFactor(worldPos);
    // o.screenPos = ComputeScreenPos(o.pos);
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
    #if defined(_PARALLAX_ON)
    // if(_ParallaxOn)
    {
        uv += ParallaxMapOffset(_HeightScale,i.viewTangentSpace,height);
    }
    #endif

    // pbrMask
    float4 pbrMask = SAMPLE_TEXTURE2D(_MetallicMap,sampler_MetallicMap ,uv);
    float metallic = pbrMask[_MetallicChannel] * _Metallic;
    // pbrMask'g is smoothness or roughness ?
    float smoothness = pbrMask[_SmoothnessChannel];
    smoothness = lerp(smoothness , 1 - smoothness,_InvertSmoothnessOn)  * _Smoothness;

    float occlusion = lerp(1,pbrMask[_OcclusionChannel] , _Occlusion);
    
    float detailMask=0;
    float4 mainTex = CalcAlbedo(uv,detailMask/*out*/);
    mainTex *= _Color;

    float3 albedo = mainTex.rgb;
    // albedo.rgb *= occlusion; // more dark than urp'lit
    float alpha = _AlphaFrom == ALPHA_FROM_MAIN_TEX ? mainTex.a : pbrMask.a * _Color.a;

    #if defined(_ALPHA_TEST)
    // if(_AlphaTestOn)
        clip(alpha - _Cutoff);
    #endif

    WorldData worldData;
    InitWorldData(uv,detailMask,i.tSpace0,i.tSpace1,i.tSpace2,worldData/**/);

    Light light = GetMainLight();
    OffsetMainLight(light);
    float3 lightColorNoAtten = light.color;

    #if defined(_RECEIVE_SHADOWS_ON)
    // if(_ApplyShadowOn)
    {
        i._ShadowCoord = TransformWorldToShadowCoord(worldData.pos.xyz); // in vert, has bug
        float atten = CalcShadow(i._ShadowCoord,worldData.pos,_MainLightShadowSoftScale);
        light.shadowAttenuation = atten;
    }
    #endif

    SurfaceData surfaceData;
    InitSurfaceData(i.uv.zw,albedo,alpha,metallic,surfaceData/**/);

    PBSData pbsData;
    InitPBSData(worldData.tangent,worldData.binormal,worldData.normal,worldData.view,surfaceData.oneMinusReflectivity, smoothness,heightClothSSSMask,worldData.pos,pbsData/**/);
    pbsData.mainTex = mainTex;
    pbsData.maskData_None_mainTexA_pbrMaskA = float3(1,mainTex.a,pbrMask.a);

    UnityIndirect indirect = CalcGI(surfaceData.diffColor,uv,worldData.reflect,worldData.normal,occlusion,pbsData.perceptualRoughness);

    #if defined(_POWER_DEBUG)
        return ShowDebug(indirect,worldData,surfaceData,metallic,smoothness,occlusion);
    #endif

    // calc coat data
    ClearCoatData coatData = (ClearCoatData)0;
    #if defined(_CLEARCOAT)
        InitCoatData(_CoatSmoothness,_ClearCoatSpecColor.xyz * surfaceData.specColor,unity_ColorSpaceDielectricSpec.x,coatData/**/);

        coatData.reflectDir = worldData.reflect;
        coatData.occlusion = occlusion;
    #endif 

    float4 col = CalcPBS(surfaceData.diffColor, surfaceData.specColor, light, indirect,coatData,pbsData/**/);
    col.a = surfaceData.finalAlpha;

    //for preintegrated lut
    #if defined(_PRESSS)
    // if(_ScatteringLUTOn)
    {
        float3 lightColor = _LightColorNoAtten ? lightColorNoAtten : light.color;
        float3 scatteredColor = PreScattering(worldData.vertexNormal,light.direction,lightColor,pbsData.nl,mainTex,worldData.pos,_CurvatureScale,_ScatteringIntensity,pbsData.maskData_None_mainTexA_pbrMaskA);
        col.rgb += scatteredColor;
    }
    #endif
    
    #if defined(_SSSS)
    // if(_DiffuseProfileOn)
    {
        float2 screenUV = i.pos.xy / _ScreenParams.xy;
        float profileMask = GetMaskForIntensity(pbsData.maskData_None_mainTexA_pbrMaskA,_SSSSMaskFrom,_SSSSMaskUsage,SSSS_MASK_FOR_INTENSITY);

        float3 sss = col.xyz;
        sss.xyz += DiffuseProfile(sss.xyz,TEXTURE2D_ARGS(_CameraOpaqueTexture,sampler_linear_repeat),screenUV,float2(_CameraOpaqueTexture_TexelSize.x * _BlurSize,0),profileMask,_DiffuseProfileBaseScale);

        sss.xyz += DiffuseProfile(sss.xyz,TEXTURE2D_ARGS(_CameraOpaqueTexture,sampler_linear_repeat),screenUV,float2(0,_CameraOpaqueTexture_TexelSize.y * _BlurSize),profileMask,_DiffuseProfileBaseScale);
        sss.xyz *=0.3333;

        float profileRate = lerp(0.2,1,light.shadowAttenuation);
        col.xyz = lerp(col.xyz,sss,profileRate);
    }
    #endif

    #if defined(_FAST_SSS)
    // if(_SSSOn)
    {
        col.rgb += CalcSSS(light.direction,worldData.view,heightClothSSSMask.zw);
    }
    #endif

    //for emission
    if(_EmissionOn){
        col.rgb += CalcEmission(surfaceData.diffColor,uv);
    }

    // apply _FresnelAlpha
    col.a *= lerp(1,saturate(smoothstep(_FresnelAlphaRange.x,_FresnelAlphaRange.y,pbsData.nv)),_FresnelAlphaOn);

    // apply sphere fog
    BlendFogSphere(col.xyz/**/,worldData.pos,i.fogCoord.xy,true,false);
    return col;
}

#endif // POWER_PBS_FORWARD_HLSL