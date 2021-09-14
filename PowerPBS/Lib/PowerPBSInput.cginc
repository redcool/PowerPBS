#if !defined(POWER_PBS_INPUT_CGINC)
#define POWER_PBS_INPUT_CGINC
#include "Common.hlsl"
#include "StrandSpecLib.cginc"

#define MAX_SPECULAR 25
// detail map mode id
#define DETAIL_MAP_MODE_MULTIPLY 0
#define DETAIL_MAP_MODE_REPLACE 1

#define ALPHA_FROM_MAIN_TEX 0
SamplerState sampler_linear_repeat;

TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
TEXTURE2D(_MetallicMap); SAMPLER(sampler_MetallicMap);//metallicSmoothnessOcclusion,
TEXTURE2D(_HeightClothSSSMask);SAMPLER(sampler_HeightClothSSSMask);
TEXTURE2D(_Detail_Map);SAMPLER(sampler_Detail_Map);

TEXTURE2D(_Detail_NormalMap);SAMPLER(sampler_Detail_NormalMap);
TEXTURE2D(_Detail1_Map);SAMPLER(sampler_Detail1_Map);
TEXTURE2D(_Detail2_Map);SAMPLER(sampler_Detail2_Map);
TEXTURE2D(_Detail3_Map);SAMPLER(sampler_Detail3_Map);
TEXTURE2D(_Detail4_Map);SAMPLER(sampler_Detail4_Map);

TEXTURECUBE(_EnvCube);SAMPLER(sampler_EnvCube);
TEXTURE2D(_EmissionMap);SAMPLER(sampler_EmissionMap);
TEXTURE2D(_ScatteringLUT);SAMPLER(sampler_ScatteringLUT);
TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture);

   //_Detail1_MapOn
 //_Detail1_MapMode
   //_Detail1_MapIntensity
    //_Detail1_Map_ST
#define DECLARE_DETAIL(id)\
    int _Detail##id##_MapOn;\
    int _Detail##id##_MapMode;\
    float _Detail##id##_MapIntensity;\
    float4 _Detail##id##_Map_ST

//------------------------- main texture
CBUFFER_START(UnityPerMaterial)
    float4 _Color;
    float4 _MainTex_ST;
    float4 _MainTex_TexelSize;
    float4 _NormalMap_ST;
    float _NormalMapScale;
    float4 _CameraOpaqueTexture_TexelSize;

    float _Smoothness;
    float _Metallic;
    float _Occlusion;
    float _Cutoff;
    int _PBRMode; // standard,aniso,fabric,strand
    float _SpecularOn;
    float _FresnelIntensity;
    float _MetallicChannel;
    float _SmoothnessChannel;
    float _OcclusionChannel;

    int _ClearCoatOn;
    float4 _ClearCoatSpecColor;
    float _CoatSmoothness;

    int _AlphaFrom;
    int _FresnelAlphaOn;
    float _FresnelMin,_FresnelMax;
// ==================================================
    float _VertexScale;
    int _VertexColorRAttenOn;
// ==================================================
    float _AnisoRough;
    float _AnisoIntensity;
    float4 _AnisoColor;

    int _AnisoLayer2On;
    float _Layer2AnisoRough;
    float _Layer2AnisoIntensity;
    float4 _Layer2AnisoColor;
    float _AnisoMaskUseMainTexA;
// ==================================================
    float4 _ClothSheenColor;
    float _ClothDMax,_ClothDMin;
    int _ClothGGXUseMainTexA;
// ==================================================
    int _ApplyShadowOn;
    int _ReceiveAdditionalLightsOn;
    int _ReceiveAdditionalLightsShadowOn;
    int _AdditionalLightSoftShadowOn;
    int _DirectionalLightFromSHOn;
    float _AmbientSHIntensity;
// ==================================================
    int _ScatteringLUTOn;
    float _ScatteringIntensity;
    float _CurvatureScale;
    int _LightColorNoAtten;
    int _AdditionalLightCalcScatter;
    int _DiffuseProfileOn;
    float _BlurSize;
    int _DiffuseProfileMaskUserMainTexA;
// ================================================== detail maps
    // main detail normalMap
    float4 _Detail_NormalMap_ST;
    float _Detail_NormalMapScale;
    DECLARE_DETAIL();
    DECLARE_DETAIL(1);
    DECLARE_DETAIL(2);
    DECLARE_DETAIL(3);
    DECLARE_DETAIL(4);
// ================================================== ibl
    float _CustomIBLOn;
    float _EnvIntensity;
    float3 _ReflectionOffsetDir;

    float _EmissionOn;
    float4 _EmissionColor;
    float _Emission;
    float _IndirectIntensity;
    float _BackFaceGIDiffuse;

    int _AlphaTestOn;
    int _AlphaPreMultiply;

// ================================================== custom light
    int _CustomLightOn;
    fixed4 _LightDir;
    fixed4 _LightColor;

    int _SSSOn;
    float3 _BackSSSColor,_FrontSSSColor;
    float _FrontSSSIntensity,_BackSSSIntensity;
    int _AdditionalLightCalcFastSSS;
// ================================================== parallel
    int _ParallalOn;
    float _HeightScale;

// ================================================== strandSpec parameters
    float _Shift1,_Shift2;
    float _SpecPower1, _SpecPower2;
    float3 _SpecColor1,_SpecColor2;
    float _SpecIntensity1,_SpecIntensity2;
    float _HairAoIntensity;

CBUFFER_END

#endif //POWER_PBS_INPUT_CGINC