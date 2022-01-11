#if !defined(LIGHTING_HLSL)
#define LIGHTING_HLSL

#include "Lib/Core/CommonUtils.hlsl"

struct BRDFData{
    half reflectivity; // metallic
    half3 diffuse;
    half3 specular;
    half perceptualRoughness,rough,rough2;
    // half normalizedTerm,roughness2MinusOne;
};

half CalcSpecularDirect(BRDFData brdfData,half3 normal,half3 lightDir,half3 viewDir){
    half3 h = normalize(lightDir + viewDir);
    half lh = saturate(dot(lightDir,h));
    half nh = saturate(dot(normal,h));
    return MinimalistCookTorrance(nh,lh,brdfData.rough,brdfData.rough2);
}


struct Light{
    half3 color;
    half3 dir;
    half distanceAttenuation;
};


void InitBRDFData(half3 albedo,half rough,half metallic,out BRDFData data){
    data.reflectivity = metallic;
    data.diffuse = albedo * (1 - data.reflectivity);
    data.specular = lerp(0.04,albedo,data.reflectivity);
    data.perceptualRoughness = rough;
    data.rough = data.perceptualRoughness * data.perceptualRoughness;
    data.rough2 = data.rough * data.rough;
}

half3 CalcPBS(BRDFData brdfData,half3 lightColor,half3 lightDir,half3 normal,half3 viewDir){
    half nl = saturate(dot(normal,lightDir));
    half3 radiance = lightColor * nl;

    half3 diff = brdfData.diffuse;
    half3 spec = brdfData.specular * CalcSpecularDirect(brdfData,normal,lightDir,viewDir);
    return (diff + spec) * radiance;
}

#endif //LIGHTING_HLSL