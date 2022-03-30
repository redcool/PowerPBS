#if !defined(BSDF_HLSL)
#define BSDF_HLSL
#include "CommonUtils.hlsl"
#include "Colors.hlsl"

inline half FastSSS(half3 l,half3 v){
    return saturate(dot(l,v));
}

inline half DisneyDiffuse(half nv,half nl,half lh,half roughness){
    half fd90 = 0.5 + 2*roughness*lh*lh;
    half lightScatter = 1 - (fd90 - 1) * Pow5(1 - nl);
    half viewScatter = 1 - (fd90 - 1 ) * Pow5(1 - nv);
    return lightScatter * viewScatter;
}
inline half RoughnessToSpecPower(half a){
    half a2 = a * a;
    half sq = max(1e-4f,a2 * a2);
    half n = 2.0/sq - 2;
    n = max(n,1e-4f);
    return n;
}
inline half3 FresnelTerm(half3 F0,half lh){
    return F0 + (1-F0) * Pow5(1 - lh);
}
inline half3 FresnelLerp(half3 f0,half3 f90,half lh){
    half t = Pow5(1-lh);
    return lerp(f0,f90,t);
}
inline half3 FresnelLerpFast(half3 F0,half3 F90,half lh){
    half t = Pow4(1 - lh);
    return lerp(F0,F90,t);
}

inline half SmithJointGGXTerm(half nl,half nv,half a2){
    half v = nv * (nv * (1-a2)+a2);
    half l = nl * (nl * (1-a2)+a2);
    return 0.5f/(v + l + 1e-5f);
}

inline half NDFBlinnPhongTerm(half nh,half a){
    half normTerm = (a + 2)* 0.5/PI;
    half specularTerm = pow(nh,a);
    return normTerm * specularTerm;
}

inline half D_GGXTerm(half nh,half a2){
    half d = (nh*a2-nh)*nh + 1;
    return a2 / (d*d + 1e-7f);
}


inline half D_GGXAnisoNoPI(half TdotH, half BdotH, half NdotH, half roughnessT, half roughnessB)
{
    half a2 = roughnessT * roughnessB;
    half3 v = half3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
    half  s = dot(v, v);

    // If roughness is 0, returns (NdotH == 1 ? 1 : 0).
    // That is, it returns 1 for perfect mirror reflection, and 0 otherwise.
    return SafeDiv(a2 * a2 * a2, s * s);
}

half D_GGXAniso(half TdotH, half BdotH, half NdotH, half roughnessT, half roughnessB)
{
    return INV_PI * D_GGXAnisoNoPI(TdotH, BdotH, NdotH, roughnessT, roughnessB);
}

half D_WardAniso(half nl,half nv,half nh,half th,half bh,half roughT,half roughB){
    half roughTH = th/roughT;
    half roughBH = bh/roughB;
    return sqrt(max(0,nl/nv)) * exp(-2 * (roughTH*roughTH+roughBH*roughBH)/(1+nh));
}

half BankBRDF(half3 l,half3 v,half3 t,half ks,half power){
    half lt = dot(l,t);
    half vt = dot(v,t);
    half lt2 = lt*lt;
    half vt2 = vt*vt;
    return ks * pow(sqrt(1-lt2)*sqrt(1-vt2) - lt*vt,power);
}

half GetSmithJointGGXAnisoPartLambdaV(half TdotV, half BdotV, half NdotV, half roughnessT, half roughnessB)
{
    return length(half3(roughnessT * TdotV, roughnessB * BdotV, NdotV));
}

// Note: V = G / (4 * NdotL * NdotV)
// Ref: https://cedec.cesa.or.jp/2015/session/ENG/14698.html The Rendering Materials of Far Cry 4
half V_SmithJointGGXAniso(half TdotV, half BdotV, half NdotV, half TdotL, half BdotL, half NdotL, half roughnessT, half roughnessB, half partLambdaV)
{
    half lambdaV = NdotL * partLambdaV;
    half lambdaL = NdotV * length(half3(roughnessT * TdotL, roughnessB * BdotL, NdotL));

    return 0.5 / (lambdaV + lambdaL);
}

half V_SmithJointGGXAniso(half TdotV, half BdotV, half NdotV, half TdotL, half BdotL, half NdotL, half roughnessT, half roughnessB)
{
    half partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);
    return V_SmithJointGGXAniso(TdotV, BdotV, NdotV, TdotL, BdotL, NdotL, roughnessT, roughnessB, partLambdaV);
}
// Inline D_GGXAniso() * V_SmithJointGGXAniso() together for better code generation.
half DV_SmithJointGGXAniso(half TdotH, half BdotH, half NdotH, half NdotV,
                           half TdotL, half BdotL, half NdotL,
                           half roughnessT, half roughnessB, half partLambdaV)
{
    half a2 = roughnessT * roughnessB;
    half3 v = half3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
    half  s = dot(v, v);

    half lambdaV = NdotL * partLambdaV;
    half lambdaL = NdotV * length(half3(roughnessT * TdotL, roughnessB * BdotL, NdotL));

    half2 D = half2(a2 * a2 * a2, s * s);  // Fraction without the multiplier (1/Pi)
    half2 G = half2(1, lambdaV + lambdaL); // Fraction without the multiplier (1/2)

    // This function is only used for direct lighting.
    // If roughness is 0, the probability of hitting a punctual or directional light is also 0.
    // Therefore, we return 0. The most efficient way to do it is with a max().
    return (INV_PI * 0.5) * (D.x * G.x) / max(D.y * G.y, FLT_MIN);
}

half DV_SmithJointGGXAniso(half TdotH, half BdotH, half NdotH,
                           half TdotV, half BdotV, half NdotV,
                           half TdotL, half BdotL, half NdotL,
                           half roughnessT, half roughnessB)
{
    half partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);
    return DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, NdotV,
                                 TdotL, BdotL, NdotL,
                                 roughnessT, roughnessB, partLambdaV);
}

half CharlieD(half roughness, half ndoth)
{
    half invR = 1. / roughness;
    half cos2h = ndoth * ndoth;
    half sin2h = max(1. - cos2h,0.0078125);
    return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI);
}

half AshikhminV(half ndotv, half ndotl)
{
    return 1. / (4. * (ndotl + ndotv - ndotl * ndotv));
}

half D_Ashikhmin(half roughness, half NoH) {
    // Ashikhmin 2007, "Distribution-based BRDFs"
	half a2 = roughness * roughness;
	half cos2h = NoH * NoH;
	half sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	half sin4h = sin2h * sin2h;
	half cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}

half MinimalistCookTorrance(half nh,half lh,half rough,half rough2){
    half d = nh * nh * (rough2-1) + 1.00001f;
    half lh2 = lh * lh;
    half spec = rough2/((d*d) * max(0.1,lh2) * (rough*4+2)); // approach sqrt(rough2)
    
    #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
        spec = clamp(spec,0,100);
    #endif
    return spec;
}

half3 ThinFilm(half invertNV,half scale,half offset,half saturate,half brightness){
    half h = invertNV * scale + offset;
    half s = saturate;
    half v = brightness;
    return HSVToRGB(half3(h,s,v));
}
#endif //BSDF_HLSL