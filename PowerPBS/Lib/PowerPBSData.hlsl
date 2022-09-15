#if !defined(POWER_PBS_DATA_HLSL)
#define POWER_PBS_DATA_HLSL

#include "PowerPBSInput.hlsl"


// Mask System
#define ANISO_MASK_FOR_INTENSITY 1
#define ANISO_MASK_FOR_BLEND_STANDARD 2

#define CLOTH_MASK_FOR_INTENSITY 1
#define CLOTH_MASK_FOR_BLEND_STANDARD 2

#define PRESSS_MASK_FOR_INTENSITY 1
#define SSSS_MASK_FOR_INTENSITY 1

#define THIN_FILE_MASK_FOR_INTENSITY 1


struct PBSData{
    float3 tangent;
    float3 binormal;
    float3 normal;
    float3 viewDir;
    half4 heightClothFastSSSMask;
    half3 hairSpecColor;
    float oneMinusReflectivity;
    float smoothness;
    float3 worldPos;
    half4 mainTex;
    float3 lightDir;
    float3 halfDir;
    float perceptualRoughness,roughness,roughness2;
    half3 maskData_None_mainTexA_pbrMaskA;
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
    half3 specColor;
    // half3 diffColor;
    float3 reflectDir;
};
void InitCoatData(float smoothness,half3 specColor,float oneMinusReflectivity,out ClearCoatData data){
    data = (ClearCoatData)0;
    data.smoothness = smoothness;
    data.perceptualRoughness = max(1-smoothness,HALF_MIN_SQRT);
    data.roughness  = max(data.perceptualRoughness * data.perceptualRoughness,HALF_MIN_SQRT);
    data.roughness2 = data.roughness * data.roughness;
    data.specColor  = specColor;
    data.oneMinusReflectivity = oneMinusReflectivity;
}


struct SurfaceData{
    half3 diffColor,specColor;
    float oneMinusReflectivity,finalAlpha;
};

struct WorldData{
    float3 pos,view,reflect;
    float3 tangent,binormal,normal;
    float3 vertexNormal,vertexTangent,vertexBinormal;
};



#endif //POWER_PBS_DATA_HLSL