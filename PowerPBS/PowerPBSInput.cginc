#if !defined(POWER_PBS_INPUT_CGINC)
#define POWER_PBS_INPUT_CGINC
#include "StrandSpecLib.cginc"

#define MAX_SPECULAR 25

sampler2D _MainTex;
sampler2D _NormalMap;

sampler2D _MetallicMap; //metallicSmoothnessOcclusion,
sampler2D _HeightClothSSSMask;

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

samplerCUBE _EnvCube;
sampler2D _EmissionMap;

//------------------------- main texture
CBUFFER_START(UnityPerMaterial)
    float4 _Color;
    float4 _MainTex_ST;
    float _NormalMapScale;
    int _ApplyShadowOn;

    float _Smoothness;
    float _Metallic;
    float _Occlusion;
    float _Cutoff;

    //-------------------------- detail map 

    int _DetailMapOn;
    int _DetailMapMode;
    float _DetailMapIntensity;
    float4 _DetailMap_ST;
    float4 _DetailNormalMap_ST;
    float _DetailNormalMapScale;
    //Mouth
    int _Detail1_MapOn;
    int _Detail1_MapMode;
    float _Detail1_MapIntensity;
    float4 _Detail1_Map_ST;
    //UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail1_NormalMap);
    //float4 _Detail1_NormalMap_ST;
    //float _Detail1_NormalMapScale;
    //Eye
    int _Detail2_MapOn;
    int _Detail2_MapMode;
    float _Detail2_MapIntensity;
    float4 _Detail2_Map_ST;
    //UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail2_NormalMap);
    //float4 _Detail2_NormalMap_ST;
    //float _Detail2_NormalMapScale;
    //Eyebrow
    int _Detail3_MapOn;
    int _Detail3_MapMode;
    float _Detail3_MapIntensity;
    float4 _Detail3_Map_ST;
    //UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail3_NormalMap);
    //float4 _Detail3_NormalMap_ST;
    //float _Detail3_NormalMapScale;
    //Face
    int _Detail4_MapOn;
    int _Detail4_MapMode;
    float _Detail4_MapIntensity;
    float4 _Detail4_Map_ST;
    //UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail4_NormalMap);
    //float4 _Detail4_NormalMap_ST;
    //float _Detail4_NormalMapScale;

    //---------------------------- ibl

    float _EnvIntensity;
    float3 _ReflectionOffsetDir;

    float4 _EmissionColor;
    float _Emission;
    float _IndirectIntensity;

    int _AlphaTestOn;
    int _AlphaPreMultiply;

    int _ClothOn;
    float _ClothSpecWidthMin;
    float _ClothSpecWidthMax;
    int _ClothMaskOn;

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