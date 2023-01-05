#if !defined (EXTRACT_LIGHT_FROM_SH_HLSL)
#define EXTRACT_LIGHT_FROM_SH_HLSL

// #include "../UnityLib/UnityShaderVariables.hlsl"
#include "Lib/Tools/Common.hlsl"

// #define PI 3.1415926
// #define BAND0_FACTOR 0.5 / sqrt(PI) 
// #define BAND1_FACTOR sqrt(1.0 / 3.0 / PI)
// #define BAND2_FACTOR_COMMON 0.125 * sqrt(15.0 / PI)
// #define BAND2_FACTOR_M0 0.0625 * sqrt(5.0 / PI)

#define BAND0_FACTOR 0.2820948
#define BAND1_FACTOR 0.325735
#define BAND2_FACTOR_COMMON 0.0869422
#define BAND2_FACTOR_M0 0.0788479

struct SHL2
{
    float3 data[9];
};

SHL2 GetOriginalSHFromUnityLightProbe()
{
    SHL2 sh;
    // band 0
    sh.data[0] = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) / BAND0_FACTOR;

    // band 1
    sh.data[1] = -float3(unity_SHAr.y, unity_SHAg.y, unity_SHAb.y) / BAND1_FACTOR;
    sh.data[2] = float3(unity_SHAr.z, unity_SHAg.z, unity_SHAb.z) / BAND1_FACTOR;
    sh.data[3] = -float3(unity_SHAr.x, unity_SHAg.x, unity_SHAb.x) / BAND1_FACTOR;
    
    // band 2
    sh.data[4] = float3(unity_SHBr.x, unity_SHBg.x, unity_SHBb.x) / BAND2_FACTOR_COMMON;
    sh.data[5] = -float3(unity_SHBr.y, unity_SHBg.y, unity_SHBb.y) / BAND2_FACTOR_COMMON;
    sh.data[6] = float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / BAND2_FACTOR_M0;
    sh.data[7] = -float3(unity_SHBr.w, unity_SHBg.w, unity_SHBb.w) / BAND2_FACTOR_COMMON;
    sh.data[8] = float3(unity_SHC.x, unity_SHC.y, unity_SHC.z) * 2 / BAND2_FACTOR_COMMON;

    return sh;
}
#define LUMINANCE(c) dot(float3(.2,.7,.02),c)
float3 GetLightDirFromSH(SHL2 sh)
{
    // float3 lightDirR = normalize(float3(-sh.data[3].r, -sh.data[1].r, sh.data[2].r));
    // float3 lightDirG = normalize(float3(-sh.data[3].g, -sh.data[1].g, sh.data[2].g));
    // float3 lightDirB = normalize(float3(-sh.data[3].b, -sh.data[1].b, sh.data[2].b));
    // lightDir = normalize( 0.3*lightDirR + 0.59*lightDirG + 0.11*lightDirB );
    //lightDir = normalize( lightDirR );

    float luminSH1 = LUMINANCE(float3(sh.data[1].r, sh.data[1].g, sh.data[1].b));
    float luminSH2 = LUMINANCE(float3(sh.data[2].r, sh.data[2].g, sh.data[2].b));
    float luminSH3 = LUMINANCE(float3(sh.data[3].r, sh.data[3].g, sh.data[3].b));

    return normalize(float3(-luminSH3, -luminSH1, luminSH2));
}

void GetLightDirAndColorFromSH(SHL2 sh, out float3 lightDir, out float3 lightColor)
{
    lightDir = GetLightDirFromSH(sh);

    float3 sh0Light = float3(0.282094791, 
                            -0.488602511*lightDir.y, 
                            0.488602511*lightDir.z);

    float3 sh1Light = float3(-0.488602511*lightDir.x, 
                            1.092548431*lightDir.y*lightDir.x, 
                            -1.092548431*lightDir.y*lightDir.z);

    float3 sh2Light = float3(0.315391565*(3.0*lightDir.z*lightDir.z-1.0), 
                            -1.092548431*lightDir.x*lightDir.z, 
                            0.546274215*(lightDir.x*lightDir.x - lightDir.y*lightDir.y));

    sh0Light *= 2.956793086;
    sh1Light *= 2.956793086;
    sh2Light *= 2.956793086;

    float denom = dot(sh0Light, sh0Light) + dot(sh1Light, sh1Light) + dot(sh2Light, sh2Light);
    
    lightColor = float3(
        dot(float3(sh.data[0].r, sh.data[1].r, sh.data[2].r), sh0Light) + 
        dot(float3(sh.data[3].r, sh.data[4].r, sh.data[5].r), sh1Light) + 
        dot(float3(sh.data[6].r, sh.data[7].r, sh.data[8].r), sh2Light),

        dot(float3(sh.data[0].g, sh.data[1].g, sh.data[2].g), sh0Light) + 
        dot(float3(sh.data[3].g, sh.data[4].g, sh.data[5].g), sh1Light) + 
        dot(float3(sh.data[6].g, sh.data[7].g, sh.data[8].g), sh2Light),

        dot(float3(sh.data[0].b, sh.data[1].b, sh.data[2].b), sh0Light) + 
        dot(float3(sh.data[3].b, sh.data[4].b, sh.data[5].b), sh1Light) + 
        dot(float3(sh.data[6].b, sh.data[7].b, sh.data[8].b), sh2Light)
        );

    lightColor /= denom;
}

Light GetDirLightFromUnityLightProbe()
{
    float3 lightDir;
    float3 lightColor;

    SHL2 sh = GetOriginalSHFromUnityLightProbe();
    GetLightDirAndColorFromSH(sh, lightDir, lightColor);

    Light light;
    light.direction = lightDir;
    light.color = lightColor;
    light.distanceAttenuation = 1;
    light.shadowAttenuation = 1;

    return light;
}
float HasLightProbe()
{
    if (dot(unity_SHAr, unity_SHAr) == 0 && dot(unity_SHAg, unity_SHAg) == 0 && dot (unity_SHBb, unity_SHBb) == 0)
        return 0;
    else
        return 1;
}
#endif 