#if !defined(COMMON_HLSL)
#define COMMON_HLSL

// #define PI 3.1415926
// #define INV_PI 0.31830988618f
#define PI2 6.283
#define DielectricSpec 0.04
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_float_Formats
#define HALF_MIN_SQRT 0.0078125
#define FLT_MIN  1.175494351e-38

#define unity_ColorSpaceDouble float4(4.59479380, 4.59479380, 4.59479380, 2.0)
#define unity_ColorSpaceDielectricSpec float4(0.04, 0.04, 0.04, 1.0 - 0.04) 
#define kDielectricSpec unity_ColorSpaceDielectricSpec

//---------- custom symbols
#define branch_if UNITY_BRANCH if

// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "../../PowerShaderLib/Lib/UnityLib.hlsl"

struct UnityIndirect
{
    float3 diffuse;
    float3 specular;
};

float OneMinusReflectivityFromMetallic(float metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    float oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

float3 DiffuseAndSpecularFromMetallic (float3 albedo, float metallic, out float3 specColor, out float oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}

#endif // COMMON_HLSL