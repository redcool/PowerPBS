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


/**
    Get Target Mask
*/
half GetMaskForIntensity(half3 maskData,half maskFrom,half maskUsage,half maskExpectUsage){
    half mask = maskData[maskFrom];
    return lerp(1,mask,maskUsage == maskExpectUsage);
}

half GetMask(half3 maskData,half maskFrom){
    return maskData[maskFrom];
}



struct PBSData{
    half3 tangent;
    half3 binormal;
    half3 normal;
    half3 viewDir;
    half4 heightClothFastSSSMask;
    half3 hairSpecColor;
    half oneMinusReflectivity;
    half smoothness;
    half3 worldPos;
    half4 mainTex;
    half3 lightDir;
    half3 halfDir;
    half perceptualRoughness,roughness,roughness2;
    // output params
    half nl;
    half nv;
    half fresnelTerm;
    half3 none_mainTexA_pbrMaskA;
};

void InitPBSData(half3 tangent,half3 binormal,half3 normal,half3 viewDir,
half oneMinusReflectivity,half smoothness,half4 heightClothFastSSSMask,half3 worldPos,out PBSData data
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
    half smoothness;
    half oneMinusReflectivity;
    half occlusion;
    half perceptualRoughness,roughness,roughness2;
    half3 specColor;
    // half3 diffColor;
    half3 reflectDir;
};
void InitCoatData(half smoothness,half3 specColor,half oneMinusReflectivity,out ClearCoatData data){
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
    half oneMinusReflectivity,finalAlpha;
};

struct WorldData{
    half3 pos,view,reflect,tangent,binormal,normal,vertexNormal,vertexTangent,vertexBinormal;
};



#endif //POWER_PBS_DATA_HLSL