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
    float _Detail##id##_MapOn;\
    float _Detail##id##_MapMode;\
    float _Detail##id##_MapIntensity;\
    float4 _Detail##id##_Map_ST

// transfereb by unity
    float4 _CameraOpaqueTexture_TexelSize;

//------------------------- main texture
CBUFFER_START(UnityPerMaterial)
    float4 _Color;
    float4 _MainTex_ST;
    float4 _MainTex_TexelSize;
    float4 _NormalMap_ST;
    float _NormalMapScale;

    float _Smoothness;
    float _Metallic;
    float _Occlusion;
    float _Cutoff;
    float _InvertSmoothnessOn;
    float _PBRMode; // standard,aniso,fabric,strand
    // float _SpecularOff; // keyword _SPECULAR_OFF
    float _SpecularIntensity;

    float _FresnelIntensity;
    float _FresnelWidth;
    float3 _FresnelColor;

    float _MetallicChannel;
    float _SmoothnessChannel;
    float _OcclusionChannel;

    // float _ClearCoatOn; // to keyword _CLEARCOAT
    float4 _ClearCoatSpecColor;
    float _CoatSmoothness;
    float _CoatIndirectSpecularIntensity;

    // float _CustomSpecularMapOn; // to keyword _SPECULAR_MAP_FLOW
    float _SpecMapScale;
    float4 _CustomSpecularMap_ST;
    float _CustomSpecularIntensity;

    float _AlphaFrom;
    float _FresnelAlphaOn;
    // float _FresnelAlphaMin,_FresnelAlphaMax;
    float2 _FresnelAlphaRange;
// ==================================================
    float _VertexScale;
    float _VertexColorRAttenOn;
// ==================================================
    float _AnisoRough;
    float _AnisoIntensity;
    float4 _AnisoColor;
    float _AnisoShift;

    float _AnisoLayer2On;
    float _Layer2AnisoRough;
    float _Layer2AnisoIntensity;
    float4 _Layer2AnisoColor;
    // float _Layer2AnisoShift;
    float _AnisoMaskFrom;
    float _AnisoIntensityUseSmoothness;
    float _AnisoMaskUsage;
    float _AnisoMaskBlendStandardAniso;
// ================================================== cloth spec
    float4 _ClothSheenColor;
    float2 _ClothSheenRange;
    float _ClothMaskFrom;
    float _ClothMaskUsage;
// ================================================== sheen layer
    // float _SheenLayerOn;
    float4 _SheenLayerRange; //xy : range[min,max],z : min luminance, w:scale
    float _SheenLayerApplyTone;
// ==================================================
    // float _ApplyShadowOn; // to _RECEIVE_SHADOWS_ON
    float _MainLightShadowSoftScale;
    float4 _ShadowColor;

    // float _ReceiveAdditionalLightsOn; // to keywords _ADDITIONAL_LIGHTS
    // float _ReceiveAdditionalLightsShadowOn; // to keywords _ADDITIONAL_LIGHT_SHADOWS
    // float _AdditionalLightSoftShadowOn; //to keyword _ADDITIONAL_LIGHT_SHADOWS_SOFT
    float _DirectionalLightFromSHOn;
    float _AmbientSHIntensity;
    float _DirectionalSHIntensity;
// ==================================================
    // float _ScatteringLUTOn; // to keyword _PRESSS
    float _ScatteringIntensity;
    float _CurvatureScale;
    float _PreScatterMaskFrom;
    float _PreScatterMaskUsage;

    float _LightColorNoAtten;
    float _AdditionalLightCalcScatter;
    // float _DiffuseProfileOn;// to keyword _SSSS
    float _BlurSize;
    float _DiffuseProfileBaseScale;
    float _SSSSMaskFrom;
    float _SSSSMaskUsage;
// ================================================== detail maps
    // main detail normalMap
    float4 _Detail_NormalMap_ST;
    float _Detail_NormalMapScale;
    DECLARE_DETAIL();
    DECLARE_DETAIL(1);
    DECLARE_DETAIL(2);
    // DECLARE_DETAIL(3);
    // DECLARE_DETAIL(4);
// ================================================== ibl
    float _CustomIBLOn;
    float _EnvIntensity;
    float3 _ReflectionOffsetDir;

    float _EmissionOn;
    float4 _EmissionColor;
    float _Emission;
    float _IndirectSpecularIntensity;
    float _BackFaceGIDiffuse;

    // float _AlphaTestOn; // to keyword _ALPHA_TEST
    float _AlphaPreMultiply;

// ================================================== custom light
    float _CustomLightOn;
    float3 _LightDir;
    float3 _LightColor;
    float _MaxSpecularIntensity;

    // float _SSSOn; //to keyword _FAST_SSS
    float3 _BackSSSColor,_FrontSSSColor;
    float _FrontSSSIntensity,_BackSSSIntensity;
    float _AdditionalLightCalcFastSSS;
// ================================================== parallel
    // float _ParallaxOn;//to keyword 
    float _HeightScale;

// ================================================== custom shadow caster params
    float4 _CustomShadowBias; // x: depth bias, y: normal bias
// ================================================== Thin Film
    float _TFScale,_TFOffset,_TFSaturate,_TFBrightness;
    float _TFMaskFrom,_TFMaskUsage,_TFSpecMask;
    float _FogOn;
// ================================================== debug data
    float _ShowGIDiff,_ShowGISpec,_ShowNormal,_ShowOcclusion;
    float _ShowMetallic,_ShowSmoothness,_ShowSpecular,_ShowDiffuse;
    // float _EnableDebug; // keyword _POWER_DEBUG

CBUFFER_END

#endif //POWER_PBS_INPUT_HLSL