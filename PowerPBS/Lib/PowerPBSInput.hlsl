#if !defined(POWER_PBS_INPUT_HLSL)
#define POWER_PBS_INPUT_HLSL
#include "Tools/Common.hlsl"

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
    half _SpecularColorScale;
    half _SpecularIntensity;

    half _FresnelIntensity;
    half _FresnelWidth;
    half3 _FresnelColor;

    half _MetallicChannel;
    half _SmoothnessChannel;
    half _OcclusionChannel;

    // half _ClearCoatOn; // to keyword _CLEARCOAT
    half4 _ClearCoatSpecColor;
    half _CoatSmoothness;
    half _CoatIndirectSpecularIntensity;

    // half _CustomSpecularMapOn; // to keyword _SPECULAR_MAP_FLOW
    half4 _CustomSpecularMap_ST;
    half _CustomSpecularIntensity;

    half _AlphaFrom;
    half _FresnelAlphaOn;
    half _FresnelAlphaMin,_FresnelAlphaMax;
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
    half _AnisoMaskFrom;
    half _AnisoIntensityUseSmoothness;
    half _AnisoMaskUsage;
    half _AnisoMaskBlendStandardAniso;
// ==================================================
    half4 _ClothSheenColor;
    half _ClothDMax,_ClothDMin;
    half _ClothMaskFrom;
    half _ClothMaskUsage;
// ==================================================
    // half _ApplyShadowOn; // to _RECEIVE_SHADOWS_ON
    half _MainLightShadowSoftScale;
    half4 _ShadowColor;

    // half _ReceiveAdditionalLightsOn; // to keywords _ADDITIONAL_LIGHTS
    // half _ReceiveAdditionalLightsShadowOn; // to keywords _ADDITIONAL_LIGHT_SHADOWS
    // half _AdditionalLightSoftShadowOn; //to keyword _ADDITIONAL_LIGHT_SHADOWS_SOFT
    half _DirectionalLightFromSHOn;
    half _AmbientSHIntensity;
    half _DirectionalSHIntensity;
// ==================================================
    // half _ScatteringLUTOn; // to keyword _PRESSS
    half _ScatteringIntensity;
    half _CurvatureScale;
    half _PreScatterMaskFrom;
    half _PreScatterMaskUsage;

    half _LightColorNoAtten;
    half _AdditionalLightCalcScatter;
    // half _DiffuseProfileOn;// to keyword _SSSS
    half _BlurSize;
    half _SSSSMaskFrom;
    half _SSSSMaskUsage;
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

    // half _AlphaTestOn; // to keyword _ALPHA_TEST
    half _AlphaPreMultiply;

// ================================================== custom light
    half _CustomLightOn;
    half4 _LightDir;
    half4 _LightColor;
    half _MaxSpecularIntensity;

    // half _SSSOn; //to keyword _FAST_SSS
    half3 _BackSSSColor,_FrontSSSColor;
    half _FrontSSSIntensity,_BackSSSIntensity;
    half _AdditionalLightCalcFastSSS;
// ================================================== parallel
    // half _ParallaxOn;//to keyword 
    half _HeightScale;

// ================================================== custom shadow caster params
    half4 _CustomShadowBias; // x: depth bias, y: normal bias
// ================================================== Thin Film
    half _TFScale,_TFOffset,_TFSaturate,_TFBrightness;
    half _TFMaskFrom,_TFMaskUsage,_TFSpecMask;
    half _FogOn;
// ================================================== debug data
    half _ShowGIDiff,_ShowGISpec,_ShowNormal,_ShowOcclusion;
    half _ShowMetallic,_ShowSmoothness,_ShowSpecular,_ShowDiffuse;
    half _EnableDebug;

CBUFFER_END

#endif //POWER_PBS_INPUT_HLSL