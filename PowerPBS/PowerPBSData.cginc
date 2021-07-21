#if !defined(POWER_PBS_DATA_CGINC)
#define POWER_PBS_DATA_CGINC

#include "PowerPBSInput.cginc"


struct PBSData{
    float3 tangent;
    float3 binormal;
    float3 normal;
    float3 viewDir;
    float clothMask;
    float3 hairSpecColor;
    float oneMinusReflectivity;
    float smoothness;
    float3 worldPos;
    // output params
    float nl;
};

inline PBSData InitPBSData(float3 tangent,float3 binormal,float3 normal,float3 viewDir,
float oneMinusReflectivity,float smoothness,float clothMask,float3 worldPos
){
    PBSData data = (PBSData)0;
    data.tangent = tangent;
    data.binormal = binormal;
    data.normal = normal;
    data.viewDir = viewDir;
    data.oneMinusReflectivity = oneMinusReflectivity;
    data.smoothness = smoothness;
    
    data.clothMask = 1;
    data.worldPos = worldPos;
    return data;
}    
#endif //POWER_PBS_DATA_CGINC