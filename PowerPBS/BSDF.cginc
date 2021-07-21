#if !defined(BSDF_CGINC)
#define BSDF_CGINC
#define PI 3.1415926
#define PI2 6.283
#define INV_PI 0.31830988618f
#define DielectricSpec 0.04
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define HALF_MIN_SQRT 0.0078125
#define FLT_MIN  1.175494351e-38

inline float FastSSS(float3 l,float3 v){
    return saturate(dot(l,v));
}

float Pow2(float a){return a*a;}
inline float Pow4(float a){
    float a2 = a*a;
    return a2*a2;
}
inline float Pow5(float a){
    float a2 = a*a;
    return a2*a2*a;
}

float SafeDiv(float numer, float denom)
{
    return (numer != denom) ? numer / denom : 1;
}
float3 SafeNormalize(float3 inVec)
{
    float3 dp3 = max(FLT_MIN, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}

inline float DisneyDiffuse(float nv,float nl,float lh,float roughness){
    float fd90 = 0.5 + 2*roughness*lh*lh;
    float lightScatter = 1 - (fd90 - 1) * Pow5(1 - nl);
    float viewScatter = 1 - (fd90 - 1 ) * Pow5(1 - nv);
    return lightScatter * viewScatter;
}

inline float RoughnessToSpecPower(float a){
    float a2 = a * a;
    float sq = max(1e-4f,a2 * a2);
    float n = 2.0/sq - 2;
    n = max(n,1e-4f);
    return n;
}

inline float SmithJointGGXTerm(float nl,float nv,float a2){
    float v = nv * (nv * (1-a2)+a2);
    float l = nl * (nl * (1-a2)+a2);
    return 0.5f/(v + l + 1e-5f);
}

inline float NDFBlinnPhongTerm(float nh,float a){
    float normTerm = (a + 2)* 0.5/PI;
    float specularTerm = pow(nh,a);
    return normTerm * specularTerm;
}

inline float D_GGXTerm(float nh,float a){
    float a2 = a  * a;
    float d = (nh*a2-nh)*nh + 1;
    return INV_PI * a2 / (d*d + 1e-7f);
}

inline float3 FresnelTerm(float3 F0,float lh){
    return F0 + (1-F0) * Pow5(1 - lh);
}
inline float3 FresnelLerp(float3 f0,float3 f90,float lh){
    float t = Pow5(1-lh);
    return lerp(f0,f90,t);
}
inline float3 FresnelLerpFast(float3 F0,float3 F90,float lh){
    float t = Pow4(1 - lh);
    return lerp(F0,F90,t);
}

inline float D_GGXAnisoNoPI(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
{
    float a2 = roughnessT * roughnessB;
    float3 v = float3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
    float  s = dot(v, v);

    // If roughness is 0, returns (NdotH == 1 ? 1 : 0).
    // That is, it returns 1 for perfect mirror reflection, and 0 otherwise.
    return SafeDiv(a2 * a2 * a2, s * s);
}

float D_GGXAniso(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
{
    return INV_PI * D_GGXAnisoNoPI(TdotH, BdotH, NdotH, roughnessT, roughnessB);
}

float D_WardAniso(float nl,float nv,float nh,float th,float bh,float roughT,float roughB){
    float roughTH = th/roughT;
    float roughBH = bh/roughB;
    return sqrt(max(0,nl/nv)) * exp(-2 * (roughTH*roughTH+roughBH*roughBH)/(1+nh));
}

float BankBRDF(float3 l,float3 v,float3 t,float ks,float power){
    float lt = dot(l,t);
    float vt = dot(v,t);
    float lt2 = lt*lt;
    float vt2 = vt*vt;
    return ks * pow(sqrt(1-lt2)*sqrt(1-vt2) - lt*vt,power);
}



float CharlieD(float roughness, float ndoth)
{
    float invR = 1. / roughness;
    float cos2h = ndoth * ndoth;
    float sin2h = max(1. - cos2h,0.0078125);
    return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI);
}

float AshikhminV(float ndotv, float ndotl)
{
    return 1. / (4. * (ndotl + ndotv - ndotl * ndotv));
}

float D_Ashikhmin(float roughness, float NoH) {
    // Ashikhmin 2007, "Distribution-based BRDFs"
	float a2 = roughness * roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	float sin4h = sin2h * sin2h;
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}

#endif //BSDF_CGINC