#if !defined(FOG_HLSL)
#define FOG_HLSL

//------------ fog
#define FOG_NONE 0
#define FOG_LINEAR 1
#define FOG_EXP 2
#define FOG_EXP2 3

int _FogMode;

#if UNITY_REVERSED_Z
    #if SHADER_API_OPENGL || SHADER_API_GLES || SHADER_API_GLES3
        //GL with reversed z => z clip range is [near, -far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(-(coord), 0)
    #else
        //D3d with reversed Z => z clip range is [near, 0] -> remapping to [0, far]
        //max is required to protect ourselves from near plane not being correct/meaningfull in case of oblique matrices.
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(((1.0-(coord)/_ProjectionParams.y)*_ProjectionParams.z),0)
    #endif
#elif UNITY_UV_STARTS_AT_TOP
    //D3d without reversed z => z clip range is [0, far] -> nothing to do
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#else
    //Opengl => z clip range is [-near, far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#endif

float ComputeFogFactor(float z)
{
    float clipZ_01 = UNITY_Z_0_FAR_FROM_CLIPSPACE(z);

    // #if defined(FOG_LINEAR)
    //     // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
    //     float fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
    //     return float(fogFactor);
    // #elif defined(FOG_EXP) || defined(FOG_EXP2)
    //     // factor = exp(-(density*z)^2)
    //     // -density * z computed at vertex
    //     return float(unity_FogParams.x * clipZ_01);
    // #else
    //     return 0.0h;
    // #endif
    if(_FogMode == FOG_LINEAR)
    {
        float fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
        return float(fogFactor); 
    }else if(_FogMode == FOG_EXP || _FogMode == FOG_EXP2){
        return float(unity_FogParams.x * clipZ_01);
    }
    return 0;
}

float ComputeFogIntensity(float fogFactor)
{
    float fogIntensity = 0.0h;
    // #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
    //     #if defined(FOG_EXP)
    //         // factor = exp(-density*z)
    //         // fogFactor = density*z compute at vertex
    //         fogIntensity = saturate(exp2(-fogFactor));
    //     #elif defined(FOG_EXP2)
    //         // factor = exp(-(density*z)^2)
    //         // fogFactor = density*z compute at vertex
    //         fogIntensity = saturate(exp2(-fogFactor * fogFactor));
    //     #elif defined(FOG_LINEAR)
    //         fogIntensity = fogFactor;
    //     #endif
    // #endif
    switch(_FogMode){
        case FOG_LINEAR : fogIntensity = fogFactor;break;
        case FOG_EXP:fogIntensity = saturate(exp2(-fogFactor)); break;
        case FOG_EXP2:fogIntensity = saturate(exp2(-fogFactor * fogFactor));break;
    }

    return fogIntensity;
}

half3 MixFogColor(float3 fragColor, float3 fogColor, float fogFactor)
{
    // #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
    //     float fogIntensity = ComputeFogIntensity(fogFactor);
    //     fragColor = lerp(fogColor, fragColor, fogIntensity);
    // #endif
    if(_FogMode != FOG_NONE)
    {
        float fogIntensity = ComputeFogIntensity(fogFactor);
        fragColor = lerp(fogColor, fragColor, fogIntensity); 
    }
    return fragColor;
}

half3 MixFog(float3 fragColor, float fogFactor)
{
    return MixFogColor(fragColor, unity_FogColor.rgb, fogFactor);
}
#endif //FOG_HLSL