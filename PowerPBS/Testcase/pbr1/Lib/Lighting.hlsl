#if !defined(LIGHTING_HLSL)
#define LIGHTING_HLSL

#include "Lib/Core/CommonUtils.hlsl"

float MinimalistCookTorrance(float nh,float lh,float rough,float rough2){
    float d = nh * nh * (rough2-1) + 1.00001f;
    float lh2 = lh * lh;
    float spec = rough2/((d*d) * max(0.1,lh2) * (rough*4+2)); // approach sqrt(rough2)
    
    #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
        spec = clamp(spec,0,100);
    #endif
    return spec;
}

struct BRDFData{
    float reflectivity; // metallic
    float3 diffuse;
    float3 specular;
    float perceptualRoughness,rough,rough2;
    // float normalizedTerm,roughness2MinusOne;
};

float CalcSpecularDirect(BRDFData brdfData,float3 normal,float3 lightDir,float3 viewDir){
    float3 h = normalize(lightDir + viewDir);
    float lh = saturate(dot(lightDir,h));
    float nh = saturate(dot(normal,h));
    return MinimalistCookTorrance(nh,lh,brdfData.rough,brdfData.rough2);
}


struct Light{
    float3 color;
    float3 dir;
    float distanceAttenuation;
};


void InitBRDFData(float3 albedo,float rough,float metallic,out BRDFData data){
    data.reflectivity = metallic;
    data.diffuse = albedo * (1 - data.reflectivity);
    data.specular = lerp(0.04,albedo,data.reflectivity);
    data.perceptualRoughness = rough;
    data.rough = data.perceptualRoughness * data.perceptualRoughness;
    data.rough2 = data.rough * data.rough;
}

float3 CalcPBS(BRDFData brdfData,float3 lightColor,float3 lightDir,float3 normal,float3 viewDir){
    float nl = saturate(dot(normal,lightDir));
    float3 radiance = lightColor * nl;

    float3 diff = brdfData.diffuse;
    float3 spec = brdfData.specular * CalcSpecularDirect(brdfData,normal,lightDir,viewDir);
    return (diff + spec) * radiance;
}

#endif //LIGHTING_HLSL