#if !defined(COMMON_HLSL)
#define COMMON_HLSL

// #define PI 3.1415926
// #define INV_PI 0.31830988618f
#define PI2 6.283
#define DielectricSpec 0.04
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_half_Formats
#define HALF_MIN_SQRT 0.0078125
#define FLT_MIN  1.175494351e-38
#define kDielectricSpec unity_ColorSpaceDielectricSpec

//---------- custom symbols
#define if UNITY_BRANCH if

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#endif // COMMON_HLSL