#if !defined(COMMON_HLSL)
#define COMMON_HLSL

#define PI 3.1415926
#define PI2 6.283
#define INV_PI 0.31830988618f
#define DielectricSpec 0.04
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_half_Formats
#define HALF_MIN_SQRT 0.0078125
#define FLT_MIN  1.175494351e-38
#define kDielectricSpec unity_ColorSpaceDielectricSpec

//---------- custom symbols
#define if UNITY_BRANCH if

// Include language header
#if defined (SHADER_API_GAMECORE)
#include "API/GameCore.hlsl"
#elif defined(SHADER_API_XBOXONE)
#include "API/XBoxOne.hlsl"
#elif defined(SHADER_API_PS4)
#include "API/PSSL.hlsl"
#elif defined(SHADER_API_PS5)
#include "API/PSSL.hlsl"
#elif defined(SHADER_API_D3D11)
#include "API/D3D11.hlsl"
#elif defined(SHADER_API_METAL)
#include "API/Metal.hlsl"
#elif defined(SHADER_API_VULKAN)
#include "API/Vulkan.hlsl"
#elif defined(SHADER_API_SWITCH)
#include "API/Switch.hlsl"
#elif defined(SHADER_API_GLCORE)
#include "API/GLCore.hlsl"
#elif defined(SHADER_API_GLES3)
#include "API/GLES3.hlsl"
#elif defined(SHADER_API_GLES)
#include "API/GLES2.hlsl"
#else
#error unsupported shader api
#endif

#endif // COMMON_HLSL