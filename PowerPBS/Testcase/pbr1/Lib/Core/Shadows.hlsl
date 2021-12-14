#if !defined(SHADOWS_HLSL)
#define SHADOWS_HLSL

#if defined(SHADER_API_MOBILE) && (defined(SHADER_API_GLES) || defined(SHADER_API_GLES30))
    #define MAX_VISIBLE_LIGHTS 16
#elif defined(SHADER_API_MOBILE) || (defined(SHADER_API_GLCORE) && !defined(SHADER_API_SWITCH)) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) // Workaround for bug on Nintendo Switch where SHADER_API_GLCORE is mistakenly defined
    #define MAX_VISIBLE_LIGHTS 32
#else
    #define MAX_VISIBLE_LIGHTS 256
#endif


#define MAX_SHADOW_CASCADES 4

TEXTURE2D_SHADOW(_MainLightShadowmapTexture);
SAMPLER_CMP(sampler_MainLightShadowmapTexture);

TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture);
SAMPLER_CMP(sampler_AdditionalLightsShadowmapTexture);

// GLES3 causes a performance regression in some devices when using CBUFFER.
#ifndef SHADER_API_GLES3
CBUFFER_START(MainLightShadows)
#endif
// Last cascade is initialized with a no-op matrix. It always transforms
// shadow coord to half3(0, 0, NEAR_PLANE). We use this trick to avoid
// branching since ComputeCascadeIndex can return cascade index = MAX_SHADOW_CASCADES
half4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
half4      _CascadeShadowSplitSpheres0;
half4      _CascadeShadowSplitSpheres1;
half4      _CascadeShadowSplitSpheres2;
half4      _CascadeShadowSplitSpheres3;
half4      _CascadeShadowSplitSphereRadii;
half4       _MainLightShadowOffset0;
half4       _MainLightShadowOffset1;
half4       _MainLightShadowOffset2;
half4       _MainLightShadowOffset3;
half4       _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise, z: oneOverFadeDist, w: minusStartFade)
half4      _MainLightShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
StructuredBuffer<ShadowData> _AdditionalShadowsBuffer;
StructuredBuffer<int> _AdditionalShadowsIndices;
half4       _AdditionalShadowOffset0;
half4       _AdditionalShadowOffset1;
half4       _AdditionalShadowOffset2;
half4       _AdditionalShadowOffset3;
half4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
#else
// GLES3 causes a performance regression in some devices when using CBUFFER.
#ifndef SHADER_API_GLES3
CBUFFER_START(AdditionalLightShadows)
#endif
half4x4    _AdditionalLightsWorldToShadow[MAX_VISIBLE_LIGHTS];
half4       _AdditionalShadowParams[MAX_VISIBLE_LIGHTS];
half4       _AdditionalShadowOffset0;
half4       _AdditionalShadowOffset1;
half4       _AdditionalShadowOffset2;
half4       _AdditionalShadowOffset3;
half4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif
#endif

half4 _ShadowBias; // x: depth bias, y: normal bias
bool _MainLightShadowOn;

#define BEYOND_SHADOW_FAR(shadowCoord) (shadowCoord.z >= 1.0 || shadowCoord.z <= 0.0)

struct ShadowSamplingData
{
    half4 shadowOffset0;
    half4 shadowOffset1;
    half4 shadowOffset2;
    half4 shadowOffset3;
    half4 shadowmapSize;
};

ShadowSamplingData GetMainLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData;
    shadowSamplingData.shadowOffset0 = _MainLightShadowOffset0;
    shadowSamplingData.shadowOffset1 = _MainLightShadowOffset1;
    shadowSamplingData.shadowOffset2 = _MainLightShadowOffset2;
    shadowSamplingData.shadowOffset3 = _MainLightShadowOffset3;
    shadowSamplingData.shadowmapSize = _MainLightShadowmapSize;
    return shadowSamplingData;
}

ShadowSamplingData GetAdditionalLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData;
    shadowSamplingData.shadowOffset0 = _AdditionalShadowOffset0;
    shadowSamplingData.shadowOffset1 = _AdditionalShadowOffset1;
    shadowSamplingData.shadowOffset2 = _AdditionalShadowOffset2;
    shadowSamplingData.shadowOffset3 = _AdditionalShadowOffset3;
    shadowSamplingData.shadowmapSize = _AdditionalShadowmapSize;
    return shadowSamplingData;
}

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
half4 GetMainLightShadowParams()
{
    return _MainLightShadowParams;
}

half4 TransformWorldToShadowCoord(half3 worldPos){
    int cascadeIndex = 0;
    half4 coord = mul(_MainLightWorldToShadow[cascadeIndex],half4(worldPos,1));
    return half4(coord.xyz,cascadeIndex);
}

half SampleShadowmap(TEXTURE2D_SHADOW_PARAM(shadowMap,sampler_shadowMap),half4 shadowCoord,ShadowSamplingData data,half4 params,bool isPerspectiveProj){
    if(isPerspectiveProj)
        shadowCoord.xyz / shadowCoord.w;
    half shadowStrength = params.x;
    half atten = 0;
    atten = SAMPLE_TEXTURE2D_SHADOW(shadowMap,sampler_shadowMap,shadowCoord.xyz);
    atten = lerp(1,atten,shadowStrength);
    return atten;
    // return BEYOND_SHADOW_FAR(shadowCoord) ? 1 : atten;
}

half MainLightRealtimeShadow(half4 shadowCoord){
    if(!_MainLightShadowOn)
        return 1;
    
    ShadowSamplingData data = GetMainLightShadowSamplingData();
    half4 params = GetMainLightShadowParams();
    return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture),shadowCoord,data,params,false);
}

half GetShadowFade(half3 positionWS)
{
    half3 camToPixel = positionWS - _WorldSpaceCameraPos;
    half distanceCamToPixel2 = dot(camToPixel, camToPixel);

    half fade = saturate(distanceCamToPixel2 * _MainLightShadowParams.z + _MainLightShadowParams.w);
    return fade * fade;
}

half MainLightShadow(half4 shadowCoord,half3 posWorld){
    half realAtten = MainLightRealtimeShadow(shadowCoord);
    half fade = GetShadowFade(posWorld);
    return lerp(realAtten,1,fade);
}

#endif //SHADOWS_HLSL