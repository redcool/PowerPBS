#if !defined(PBR_INPUT_HLSL)
#define PBR_INPUT_HLSL
#include "Lib/Core/CommonUtils.hlsl"


sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _PbrMask;

#if defined(INSTANCING_ON)
UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
    UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
    UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
    UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
    UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)

    UNITY_DEFINE_INSTANCED_PROP(float, _SpecularOn)
    UNITY_DEFINE_INSTANCED_PROP(float, _AnisoRough)
    UNITY_DEFINE_INSTANCED_PROP(float, _PbrMode)
    UNITY_DEFINE_INSTANCED_PROP(float, _CalcTangent)
UNITY_INSTANCING_BUFFER_END(Props)
#define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(Props,_MainTex_ST)
#define _Metallic UNITY_ACCESS_INSTANCED_PROP(Props,_Metallic)
#define _Smoothness UNITY_ACCESS_INSTANCED_PROP(Props,_Smoothness)
#define _Occlusion UNITY_ACCESS_INSTANCED_PROP(Props,_Occlusion)
#define _NormalScale UNITY_ACCESS_INSTANCED_PROP(Props,_NormalScale)

#define _SpecularOn UNITY_ACCESS_INSTANCED_PROP(Props,_SpecularOn)
#define _AnisoRough UNITY_ACCESS_INSTANCED_PROP(Props,_AnisoRough)
#define _PbrMode UNITY_ACCESS_INSTANCED_PROP(Props,_PbrMode)
#define _CalcTangent UNITY_ACCESS_INSTANCED_PROP(Props,_CalcTangent)
#else

CBUFFER_START(UnityPerMaterial)
float4 _MainTex_ST;
float _Metallic,_Smoothness,_Occlusion;

float _NormalScale;

bool _SpecularOn;
float _AnisoRough;

int _PbrMode;
bool _CalcTangent;

CBUFFER_END
#endif // INSTANCING_ON
#endif //PBR_INPUT_HLSL