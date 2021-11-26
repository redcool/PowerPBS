#if !defined(BSDF_HLSL)
#define BSDF_HLSL

#define PI 3.1415
#define PI2 6.28
#define INV_PI 0.318

float MinimalistCookTorrance(float nh,float lh,float a,float a2){
    float d = nh * nh * (a2 - 1)+1;
    float vf = max(lh * lh,0.1);
    float s = a2/(d*d* vf * (4*a+2));
    return s;
}

//http://web.engr.oregonstate.edu/~mjb/cs519/Projects/Papers/HairRendering.pdf
float3 ShiftTangent(float3 T, float3 N, float shift)
{
    return normalize(T + N * shift);
}

float D_GGXAnisoNoPI(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
{
    float a2 = roughnessT * roughnessB;
    float3 v = float3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
    float  s = dot(v, v);

    // If roughness is 0, returns (NdotH == 1 ? 1 : 0).
    // That is, it returns 1 for perfect mirror reflection, and 0 otherwise.
    return (a2 * a2 * a2)/max(0.0001, s * s);
}

float D_CharlieNoPI(float NdotH, float roughness)
{
    float invR = rcp(max(roughness,0.001));
    float cos2h = NdotH * NdotH;
    float sin2h = 1.0 - cos2h;
    // Note: We have sin^2 so multiply by 0.5 to cancel it
    return (2.0 + invR) * pow(sin2h, invR * 0.5) * 0.5;
}

float D_GGXNoPI(float NdotH, float a2)
{
    float s = (NdotH * a2 - NdotH) * NdotH + 1.0;
    return a2 / (1e-7f+s * s);
}

float D_GGX(float nh,float a2){
    return D_GGXNoPI(nh,a2) * INV_PI;
}

#endif //BSDF_HLSL