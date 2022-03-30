#if !defined(COLORS_HLSL)
#define COLORS_HLSL

// Converts linear RGB to LMS
// Full float precision to avoid precision artefact when using ACES tonemapping
float3 LinearToLMS(float3 x)
{
    const half3x3 LIN_2_LMS_MAT = {
        3.90405e-1, 5.49941e-1, 8.92632e-3,
        7.08416e-2, 9.63172e-1, 1.35775e-3,
        2.31082e-2, 1.28021e-1, 9.36245e-1
    };

    return mul(LIN_2_LMS_MAT, x);
}

// Full float precision to avoid precision artefact when using ACES tonemapping
float3 LMSToLinear(float3 x)
{
    const half3x3 LMS_2_LIN_MAT = {
        2.85847e+0, -1.62879e+0, -2.48910e-2,
        -2.10182e-1,  1.15820e+0,  3.24281e-4,
        -4.18120e-2, -1.18169e-1,  1.06867e+0
    };

    return mul(LMS_2_LIN_MAT, x);
}

half3 HUEToRGB(half h){
    h = frac(h);
    half r = abs(h * 6 -3) - 1;
    half g = 2 - abs(h * 6 - 2);
    half b = 2 - abs(h * 6 -4);
    return saturate(half3(r,g,b));
}

half3 HSVToRGB(half3 hsv){
    half3 rgb = HUEToRGB(hsv.x);
    // return ((rgb-1) * hsv.y + 1) * hsv.z;
    return lerp(1,rgb,hsv.y) * hsv.z;
}
#endif //COLORS_HLSL