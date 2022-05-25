#if !defined(URP_INPUT_HLSL)
#define URP_INPUT_HLSL

#define RENDERING_LIGHT_LAYERS_MASK (255)
#define RENDERING_LIGHT_LAYERS_MASK_SHIFT (0)
#define DEFAULT_LIGHT_LAYERS (RENDERING_LIGHT_LAYERS_MASK >> RENDERING_LIGHT_LAYERS_MASK_SHIFT)


// Must match: UniversalRenderPipeline.maxVisibleAdditionalLights
#if defined(SHADER_API_MOBILE) && (defined(SHADER_API_GLES) || defined(SHADER_API_GLES30))
    #define MAX_VISIBLE_LIGHTS 16
#elif defined(SHADER_API_MOBILE) || (defined(SHADER_API_GLCORE) && !defined(SHADER_API_SWITCH)) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) // Workaround because SHADER_API_GLCORE is also defined when SHADER_API_SWITCH is
    #define MAX_VISIBLE_LIGHTS 32
#else
    #define MAX_VISIBLE_LIGHTS 256
#endif

// Input.hlsl
float4 _ScaledScreenParams;

half4 _MainLightPosition;
half4 _MainLightColor;
half4 _MainLightOcclusionProbes;
uint _MainLightLayerMask;

// xyz are currently unused
// w: directLightStrength
half4 _AmbientOcclusionParam;
half4 _AdditionalLightsCount;

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
StructuredBuffer<LightData> _AdditionalLightsBuffer;
StructuredBuffer<int> _AdditionalLightsIndices;
#else
// GLES3 causes a performance regression in some devices when using CBUFFER.
#ifndef SHADER_API_GLES3
CBUFFER_START(AdditionalLights)
#endif
float4 _AdditionalLightsPosition[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsColor[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsAttenuation[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsSpotDir[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsOcclusionProbes[MAX_VISIBLE_LIGHTS];
float _AdditionalLightsLayerMasks[MAX_VISIBLE_LIGHTS]; // we want uint[] but Unity api does not support it.
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif
#endif

#endif //URP_INPUT_HLSL