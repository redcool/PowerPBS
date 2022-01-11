#if !defined(PBR_FORWARD_PASS_HLSL)
#define PBR_FORWARD_PASS_HLSL
#include "Lib/Core/CommonUtils.hlsl"
#include "Lib/Core/TangentLib.hlsl"
#include "Lib/Core/BSDF.hlsl"
#include "Lib/Core/Fog.hlsl"
#include "Lib/PBRInput.hlsl"
#include "Lib/URP_MainLightShadows.hlsl"

half3 CalcIBL(half3 viewDir, half3 n,half a){
    a = a* (1.7 - a * 0.7);
    half mip = round(a * 6);
    half3 reflectDir = reflect(-viewDir,n);
    half4 hdrEnv = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectDir,mip);
    return DecodeHDR(hdrEnv,unity_SpecCube0_HDR);
}

half3 CalcGI(){
    return 0;
}
#endif //PBR_FORWARD_PASS_HLSL