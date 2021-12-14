#if !defined(BSDF_HLSL)
#define BSDF_HLSL

#define PI 3.1415
#define PI2 6.28
#define INV_PI 0.318

half MinimalistCookTorrance(half nh,half lh,half a,half a2){
    half d = nh * nh * (a2 - 1)+1;
    half vf = max(lh * lh,0.1);
    half s = a2/(d*d* vf * (4*a+2));
    return s;
}

//http://web.engr.oregonstate.edu/~mjb/cs519/Projects/Papers/HairRendering.pdf
half3 ShiftTangent(half3 T, half3 N, half shift)
{
    return normalize(T + N * shift);
}

half D_GGXAnisoNoPI(half TdotH, half BdotH, half NdotH, half roughnessT, half roughnessB)
{
    half a2 = roughnessT * roughnessB;
    half3 v = half3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
    half  s = dot(v, v);

    // If roughness is 0, returns (NdotH == 1 ? 1 : 0).
    // That is, it returns 1 for perfect mirror reflection, and 0 otherwise.
    return (a2 * a2 * a2)/max(0.0001, s * s);
}

half D_CharlieNoPI(half NdotH, half roughness)
{
    half invR = rcp(max(roughness,0.001));
    half cos2h = NdotH * NdotH;
    half sin2h = 1.0 - cos2h;
    // Note: We have sin^2 so multiply by 0.5 to cancel it
    return (2.0 + invR) * pow(sin2h, invR * 0.5) * 0.5;
}

half D_GGXNoPI(half NdotH, half a2)
{
    half s = (NdotH * a2 - NdotH) * NdotH + 1.0;
    return a2 / (1e-7f+s * s);
}

half D_GGX(half nh,half a2){
    return D_GGXNoPI(nh,a2) * INV_PI;
}

#endif //BSDF_HLSL