#if !defined(POWER_PBS_INPUT_CGINC)
#define POWER_PBS_INPUT_CGINC
#include "StrandSpecLib.cginc"

#define MAX_SPECULAR 25

UNITY_DECLARE_TEX2D(_MainTex);
UNITY_DECLARE_TEX2D(_NormalMap);

UNITY_DECLARE_TEX2D(_MetallicMap); //metallicSmoothnessOcclusion,
UNITY_DECLARE_TEX2D(_HeightClothSSSMask);

// detail map mode id
#define DETAIL_MAP_MODE_MULTIPLY 0
#define DETAIL_MAP_MODE_REPLACE 1
SamplerState tex_linear_repeat_sampler;

UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail1_Map);
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail2_Map);
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail4_Map);
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail3_Map);

UNITY_DECLARE_TEXCUBE(_EnvCube);
UNITY_DECLARE_TEX2D(_EmissionMap);
UNITY_DECLARE_TEX2D(_ScatteringLUT);

// #define DECLARE_DETAIL(id) int _Detail_MapOn;
    // int _Detail##id_MapMode;/
    // float _Detail##id_MapIntensity;/
    // float4 _Detail##id_Map_ST/

//------------------------- main texture
CBUFFER_START(UnityPerMaterial)
    float4 _Color;
    float4 _MainTex_ST;
    float4 _NormalMap_ST;
    float _NormalMapScale;

    float _Smoothness;
    float _Metallic;
    float _Occlusion;
    float _Cutoff;

    float _AnisoOn;
    float _RoughT,_RoughB;
    float _AnisoIntensity;

    int _ApplyShadowOn;

    int _ScatteringLUTOn;
    float _ScatteringIntensity;
    float _CurvatureScale;
    //-------------------------- detail maps

    int _DetailMapOn;
    int _DetailMapMode;
    float _DetailMapIntensity;
    float4 _DetailMap_ST;
    // DECLARE_DETAIL();
    // main detail normalMap
    float4 _DetailNormalMap_ST;
    float _DetailNormalMapScale;
    //Mouth
    int _Detail1_MapOn;
    int _Detail1_MapMode;
    float _Detail1_MapIntensity;
    float4 _Detail1_Map_ST;
    //Eye
    int _Detail2_MapOn;
    int _Detail2_MapMode;
    float _Detail2_MapIntensity;
    float4 _Detail2_Map_ST;
    //Eyebrow
    int _Detail3_MapOn;
    int _Detail3_MapMode;
    float _Detail3_MapIntensity;
    float4 _Detail3_Map_ST;
    //Face
    int _Detail4_MapOn;
    int _Detail4_MapMode;
    float _Detail4_MapIntensity;
    float4 _Detail4_Map_ST;

    //---------------------------- ibl
    float _CustomIBLOn;
    float _EnvIntensity;
    float3 _ReflectionOffsetDir;

    float _EmissionOn;
    float4 _EmissionColor;
    float _Emission;
    float _IndirectIntensity;

    int _AlphaTestOn;
    int _AlphaPreMultiply;

    // -------------------------------------- main light

    //---- 当前物体的光照
    int _CustomLightOn;
    fixed4 _LightDir;
    fixed4 _LightColor;

    float3 _MainLightDir;
    float3 _MainLightColor;

    int _SSSOn;
    float3 _BackSSSColor,_FrontSSSColor;
    float _FrontSSSIntensity,_BackSSSIntensity;

    // ----------------- parallel
    int _ParallalOn;
    float _Height;

    // ----------------- strandSpec parameters
    float _Shift1,_Shift2;
    float _SpecPower1, _SpecPower2;
    float3 _SpecColor1,_SpecColor2;
    float _SpecIntensity1,_SpecIntensity2;
    float _HairAoIntensity;
    int _HairOn;


CBUFFER_END



#endif //POWER_PBS_INPUT_CGINC