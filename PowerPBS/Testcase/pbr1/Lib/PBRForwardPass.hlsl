#if !defined(PBR_FORWARD_PASS_HLSL)
#define PBR_FORWARD_PASS_HLSL
#include "Lib/Core/CommonUtils.hlsl"
#include "Lib/Core/TangentLib.hlsl"
#include "Lib/Core/BSDF.hlsl"
#include "Lib/Core/Shadows.hlsl"
#include "Lib/PBRInput.hlsl"
#include "Lib/Core/Fog.hlsl"

float3 CalcIBL(float3 viewDir, float3 n,float a){
    a = a* (1.7 - a * 0.7);
    float mip = round(a * 6);
    float3 reflectDir = reflect(-viewDir,n);
    float4 hdrEnv = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectDir,mip);
    return DecodeHDR(hdrEnv,unity_SpecCube0_HDR);
}

float3 CalcGI(){
    return 0;
}
#endif //PBR_FORWARD_PASS_HLSL