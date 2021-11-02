#if !defined (EXTRACT_LIGHT_FROM_SH_HLSL)
#define EXTRACT_LIGHT_FROM_SH_HLSL

#include "UnityLib/UnityShaderVariables.hlsl"

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
    half3 data[9];
};

SHL2 GetOriginalSHFromUnityLightProbe()
{
    SHL2 sh;
    // band 0
    sh.data[0] = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) / BAND0_FACTOR;

    // band 1
    sh.data[1] = -half3(unity_SHAr.y, unity_SHAg.y, unity_SHAb.y) / BAND1_FACTOR;
    sh.data[2] = half3(unity_SHAr.z, unity_SHAg.z, unity_SHAb.z) / BAND1_FACTOR;
    sh.data[3] = -half3(unity_SHAr.x, unity_SHAg.x, unity_SHAb.x) / BAND1_FACTOR;
    
    // band 2
    sh.data[4] = half3(unity_SHBr.x, unity_SHBg.x, unity_SHBb.x) / BAND2_FACTOR_COMMON;
    sh.data[5] = -half3(unity_SHBr.y, unity_SHBg.y, unity_SHBb.y) / BAND2_FACTOR_COMMON;
    sh.data[6] = half3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / BAND2_FACTOR_M0;
    sh.data[7] = -half3(unity_SHBr.w, unity_SHBg.w, unity_SHBb.w) / BAND2_FACTOR_COMMON;
    sh.data[8] = half3(unity_SHC.x, unity_SHC.y, unity_SHC.z) * 2 / BAND2_FACTOR_COMMON;

    return sh;
}

half3 GetLightDirFromSH(SHL2 sh)
{
    // half3 lightDirR = normalize(half3(-sh.data[3].r, -sh.data[1].r, sh.data[2].r));
    // half3 lightDirG = normalize(half3(-sh.data[3].g, -sh.data[1].g, sh.data[2].g));
    // half3 lightDirB = normalize(half3(-sh.data[3].b, -sh.data[1].b, sh.data[2].b));
    // lightDir = normalize( 0.3*lightDirR + 0.59*lightDirG + 0.11*lightDirB );
    //lightDir = normalize( lightDirR );

    half luminSH1 = Luminance(half3(sh.data[1].r, sh.data[1].g, sh.data[1].b));
    half luminSH2 = Luminance(half3(sh.data[2].r, sh.data[2].g, sh.data[2].b));
    half luminSH3 = Luminance(half3(sh.data[3].r, sh.data[3].g, sh.data[3].b));

    return normalize(half3(-luminSH3, -luminSH1, luminSH2));
}

void GetLightDirAndColorFromSH(SHL2 sh, out half3 lightDir, out half3 lightColor)
{
    lightDir = GetLightDirFromSH(sh);

    half3 sh0Light = half3(0.282094791, 
                            -0.488602511*lightDir.y, 
                            0.488602511*lightDir.z);

    half3 sh1Light = half3(-0.488602511*lightDir.x, 
                            1.092548431*lightDir.y*lightDir.x, 
                            -1.092548431*lightDir.y*lightDir.z);

    half3 sh2Light = half3(0.315391565*(3.0*lightDir.z*lightDir.z-1.0), 
                            -1.092548431*lightDir.x*lightDir.z, 
                            0.546274215*(lightDir.x*lightDir.x - lightDir.y*lightDir.y));

    sh0Light *= 2.956793086;
    sh1Light *= 2.956793086;
    sh2Light *= 2.956793086;

    half denom = dot(sh0Light, sh0Light) + dot(sh1Light, sh1Light) + dot(sh2Light, sh2Light);
    
    lightColor = half3(
        dot(half3(sh.data[0].r, sh.data[1].r, sh.data[2].r), sh0Light) + 
        dot(half3(sh.data[3].r, sh.data[4].r, sh.data[5].r), sh1Light) + 
        dot(half3(sh.data[6].r, sh.data[7].r, sh.data[8].r), sh2Light),

        dot(half3(sh.data[0].g, sh.data[1].g, sh.data[2].g), sh0Light) + 
        dot(half3(sh.data[3].g, sh.data[4].g, sh.data[5].g), sh1Light) + 
        dot(half3(sh.data[6].g, sh.data[7].g, sh.data[8].g), sh2Light),

        dot(half3(sh.data[0].b, sh.data[1].b, sh.data[2].b), sh0Light) + 
        dot(half3(sh.data[3].b, sh.data[4].b, sh.data[5].b), sh1Light) + 
        dot(half3(sh.data[6].b, sh.data[7].b, sh.data[8].b), sh2Light)
        );

    lightColor /= denom;
}

Light GetDirLightFromUnityLightProbe()
{
    half3 lightDir;
    half3 lightColor;

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