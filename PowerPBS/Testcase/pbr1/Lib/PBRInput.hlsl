#if !defined(PBR_INPUT_HLSL)
#define PBR_INPUT_HLSL
#include "Lib/Core/CommonUtils.hlsl"


sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _PbrMask;

CBUFFER_START(UnityPerMaterial)
half4 _MainTex_ST;
half _Metallic,_Smoothness,_Occlusion;

half _NormalScale;

bool _SpecularOn;
half _AnisoRough;

int _PbrMode;
bool _CalcTangent;

// custom shadow 
half _MainLightShadowSoftScale;
half2 _CustomShadowBias;

CBUFFER_END
#endif //PBR_INPUT_HLSL