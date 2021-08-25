#if !defined(COMMON_HLSL)
#define COMMON_HLSL

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