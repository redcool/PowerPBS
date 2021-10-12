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
    float perceptualRoughness,roughness,roughness2;
    // output params
    float nl;
    float nv;
    float fresnelTerm;
};

void InitPBSData(float3 tangent,float3 binormal,float3 normal,float3 viewDir,
float oneMinusReflectivity,float smoothness,float4 heightClothFastSSSMask,float3 worldPos,out PBSData data
){
    data = (PBSData)0;
    data.tangent = tangent;
    data.binormal = binormal;
    data.normal = normal;
    data.viewDir = viewDir;
    data.oneMinusReflectivity = oneMinusReflectivity;
    data.smoothness = smoothness;
    data.perceptualRoughness = 1-smoothness;
    data.roughness = max(data.perceptualRoughness * data.perceptualRoughness,HALF_MIN_SQRT);
    data.roughness2 = max(data.roughness * data.roughness,HALF_MIN);
    
    data.heightClothFastSSSMask = heightClothFastSSSMask;
    data.worldPos = worldPos;
}

struct ClearCoatData{
    float smoothness;
    float oneMinusReflectivity;
    float occlusion;
    float perceptualRoughness,roughness,roughness2;
    float3 specColor;
    // float3 diffColor;
    float3 reflectDir;
};
void InitCoatData(float smoothness,float3 specColor,float oneMinusReflectivity,out ClearCoatData data){
    data = (ClearCoatData)0;
    data.smoothness = smoothness;
    data.perceptualRoughness = max(1-smoothness,HALF_MIN_SQRT);
    data.roughness  = max(data.perceptualRoughness * data.perceptualRoughness,HALF_MIN_SQRT);
    data.roughness2 = data.roughness * data.roughness;
    data.specColor  = specColor;
    data.oneMinusReflectivity = oneMinusReflectivity;
}


struct SurfaceData{
    float3 diffColor,specColor;
    float oneMinusReflectivity,finalAlpha;
};

struct WorldData{
    float3 pos,view,reflect,tangent,binormal,normal,vertexNormal;
};


#endif //POWER_PBS_DATA_CGINC