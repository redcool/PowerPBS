#if !defined(POWER_PBS_INPUT_HLSL)
#define POWER_PBS_INPUT_HLSL
#include "Common.hlsl"
#include "StrandSpecLib.hlsl"

#define MAX_SPECULAR 25
// detail map mode id
#define DETAIL_MAP_MODE_MULTIPLY 0
#define DETAIL_MAP_MODE_REPLACE 1

#define ALPHA_FROM_MAIN_TEX 0
SamplerState sampler_linear_repeat;

TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
TEXTURE2D(_MetallicMap); SAMPLER(sampler_MetallicMap);//metallicSmoothnessOcclusion,
TEXTURE2D(_HeightClothSSSMask);//SAMPLER(sampler_HeightClothSSSMask);
TEXTURE2D(_Detail_Map);//SAMPLER(sampler_Detail_Map);

TEXTURE2D(_Detail_NormalMap);//SAMPLER(sampler_Detail_NormalMap);
TEXTURE2D(_Detail1_Map);//SAMPLER(sampler_Detail1_Map);
// TEXTURE2D(_Detail2_Map);//SAMPLER(sampler_Detail2_Map);
// TEXTURE2D(_Detail3_Map);//SAMPLER(sampler_Detail3_Map);
// TEXTURE2D(_Detail4_Map);//SAMPLER(sampler_Detail4_Map);

TEXTURECUBE(_EnvCube);//SAMPLER(sampler_EnvCube);
TEXTURE2D(_EmissionMap);//SAMPLER(sampler_EmissionMap);
TEXTURE2D(_ScatteringLUT);//SAMPLER(sampler_ScatteringLUT);
TEXTURE2D(_CameraOpaqueTexture); //SAMPLER(sampler_CameraOpaqueTexture);
TEXTURE2D(_CustomSpecularMap);


TEXTURE2D(_StrandMaskTex); // xyzw  = shift_specMask_ao_tbMask

   //_Detail1_MapOn
 //_Detail1_MapMode
   //_Detail1_MapIntensity
    //_Detail1_Map_ST
#define DECLARE_DETAIL(id)\
    half _Detail##id##_MapOn;\
    half _Detail##id##_MapMode;\
    half _Detail##id##_MapIntensity;\
    half4 _Detail##id##_Map_ST

// transfereb by unity
    half4 _CameraOpaqueTexture_TexelSize;

//------------------------- main texture
CBUFFER_START(UnityPerMaterial)
    half4 _Color;
    half4 _MainTex_ST;
    half4 _MainTex_TexelSize;
    half4 _NormalMap_ST;
    half _NormalMapScale;

    half _Smoothness;
    half _Metallic;
    half _Occlusion;
    half _Cutoff;
    half _InvertSmoothnessOn;
    half _PBRMode; // standard,aniso,fabric,strand
    half _SpecularOn;
    half _FresnelIntensity;
    half _MetallicChannel;
    half _SmoothnessChannel;
    half _OcclusionChannel;

    half _ClearCoatOn;
    half4 _ClearCoatSpecColor;
    half _CoatSmoothness;
    half _CoatIndirectSpecularIntensity;

    half _CustomSpecularMapOn;
    half4 _CustomSpecularMap_ST;
    half _CustomSpecularIntensity;

    half _AlphaFrom;
    half _FresnelAlphaOn;
    half _FresnelMin,_FresnelMax;
// ==================================================
    half _VertexScale;
    half _VertexColorRAttenOn;
// ==================================================
    half _AnisoRough;
    half _AnisoIntensity;
    half4 _AnisoColor;
    half _AnisoShift;

    half _AnisoLayer2On;
    half _Layer2AnisoRough;
    half _Layer2AnisoIntensity;
    half4 _Layer2AnisoColor;
    // half _Layer2AnisoShift;
    half _AnisoIntensityUseMainTexA;
    half _AnisoIntensityUseSmoothness;
// ==================================================
    half4 _ClothSheenColor;
    half _ClothDMax,_ClothDMin;
    half _ClothGGXUseMainTexA;
// ==================================================
    half _ApplyShadowOn;
    half _MainLightShadowSoftScale;
    half _ReceiveAdditionalLightsOn;
    half _ReceiveAdditionalLightsShadowOn;
    half _AdditionalLightSoftShadowOn;
    half _DirectionalLightFromSHOn;
    half _AmbientSHIntensity;
    half _DirectionalSHIntensity;
// ==================================================
    half _ScatteringLUTOn;
    half _ScatteringIntensity;
    half _CurvatureScale;
    half _PreScatterMaskUseMainTexA;
    half _LightColorNoAtten;
    half _AdditionalLightCalcScatter;
    half _DiffuseProfileOn;
    half _BlurSize;
    half _DiffuseProfileMaskUserMainTexA;
// ================================================== detail maps
    // main detail normalMap
    half4 _Detail_NormalMap_ST;
    half _Detail_NormalMapScale;
    DECLARE_DETAIL();
    DECLARE_DETAIL(1);
    DECLARE_DETAIL(2);
    // DECLARE_DETAIL(3);
    // DECLARE_DETAIL(4);
// ================================================== ibl
    half _CustomIBLOn;
    half _EnvIntensity;
    half3 _ReflectionOffsetDir;

    half _EmissionOn;
    half4 _EmissionColor;
    half _Emission;
    half _IndirectSpecularIntensity;
    half _BackFaceGIDiffuse;

    half _AlphaTestOn;
    half _AlphaPreMultiply;

// ================================================== custom light
    half _CustomLightOn;
    half4 _LightDir;
    half4 _LightColor;
    half _MaxSpecularIntensity;

    half _SSSOn;
    half3 _BackSSSColor,_FrontSSSColor;
    half _FrontSSSIntensity,_BackSSSIntensity;
    half _AdditionalLightCalcFastSSS;
// ================================================== parallel
    half _ParallalOn;
    half _HeightScale;

// ================================================== strandSpec parameters
    half _Shift1,_Shift2;
    half _SpecPower1, _SpecPower2;
    half3 _SpecColor1,_SpecColor2;
    half _SpecIntensity1,_SpecIntensity2;
    half _HairAoIntensity;
// ================================================== custom shadow caster params
    half4 _CustomShadowBias; // x: depth bias, y: normal bias
// ================================================== debug data
    half _ShowGIDiff;
    half _ShowGISpec;

CBUFFER_END

#endif //POWER_PBS_INPUT_HLSL