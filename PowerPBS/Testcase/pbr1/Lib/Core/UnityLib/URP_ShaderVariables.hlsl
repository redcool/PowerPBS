#if !defined(URP_SHADER_VARIABLES_HLSL)
#define URP_SHADER_VARIABLES_HLSL

///////////////////////////////////////////////////////////////////////////////
//                      Constant Buffers                                     //
///////////////////////////////////////////////////////////////////////////////

#if defined(SHADER_API_MOBILE) && (defined(SHADER_API_GLES) || defined(SHADER_API_GLES30))
    #define MAX_VISIBLE_LIGHTS 16
#elif defined(SHADER_API_MOBILE) || (defined(SHADER_API_GLCORE) && !defined(SHADER_API_SWITCH)) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) // Workaround for bug on Nintendo Switch where SHADER_API_GLCORE is mistakenly defined
    #define MAX_VISIBLE_LIGHTS 32
#else
    #define MAX_VISIBLE_LIGHTS 256
#endif

half4 _GlossyEnvironmentColor;
half4 _SubtractiveShadowColor;

#define _InvCameraViewProj unity_MatrixInvVP
half4 _ScaledScreenParams;

half4 _MainLightPosition;
half4 _MainLightColor;
half4 _MainLightOcclusionProbes;

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
half4 _AdditionalLightsPosition[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsColor[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsAttenuation[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsSpotDir[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsOcclusionProbes[MAX_VISIBLE_LIGHTS];
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif
#endif

#endif //URP_SHADER_VARIABLES_HLSL