#if !defined(POWER_PBS_DATA_CGINC)
#define POWER_PBS_DATA_CGINC

#include "PowerPBSInput.cginc"


struct PBSData{
    float3 tangent;
    float3 binormal;
    float3 normal;
    float3 viewDir;
    float4 heightClothFastSSSMask;
    float3 hairSpecColor;
    float oneMinusReflectivity;
    float smoothness;
    float3 worldPos;
    float4 mainTex;
    float3 lightDir;
    float3 halfDir;
    // output params
    float nl;
    float nv;
    float perceptualRoughness,roughness,roughness2;
};

inline PBSData InitPBSData(float3 tangent,float3 binormal,float3 normal,float3 viewDir,
float oneMinusReflectivity,float smoothness,float4 heightClothFastSSSMask,float3 worldPos
){
    PBSData data = (PBSData)0;
    data.tangent = tangent;
    data.binormal = binormal;
    data.normal = normal;
    data.viewDir = viewDir;
    data.oneMinusReflectivity = oneMinusReflectivity;
    data.smoothness = smoothness;
    data.perceptualRoughness = 1-smoothness;
    data.roughness = data.perceptualRoughness * data.perceptualRoughness;
    data.roughness2 = data.roughness * data.roughness;
    
    data.heightClothFastSSSMask = heightClothFastSSSMask;
    data.worldPos = worldPos;
    return data;
}    
#endif //POWER_PBS_DATA_CGINC