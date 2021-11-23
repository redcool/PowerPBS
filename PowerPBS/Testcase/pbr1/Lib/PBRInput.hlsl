#if !defined(PBR_INPUT_HLSL)
#define PBR_INPUT_HLSL
#include "Lib/Core/CommonUtils.hlsl"


sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _PbrMask;

CBUFFER_START(UnityPerMaterial)
float4 _MainTex_ST;
float _Metallic,_Smoothness,_Occlusion;

float _NormalScale;

bool _SpecularOn;
float _AnisoRough;

int _PbrMode;
bool _CalcTangent;

CBUFFER_END
#endif //PBR_INPUT_HLSL