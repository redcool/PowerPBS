// Upgrade NOTE: replaced 'defined SIMPLE_PBS_CORE_CGINC' with 'defined (SIMPLE_PBS_CORE_CGINC)'

#if !defined (SIMPLE_PBS_CORE_CGINC)
#define SIMPLE_PBS_CORE_CGINC

#include "UnityLightingCommon.cginc"

#define PI 3.1415926
#define INV_PI 0.31830988618f
#define DielectricSpec 0.04

//------------------------- main texture

sampler2D _MainTex;
float4 _Color;
float4 _MainTex_ST;
sampler2D _NormalMap;
float _NormalMapScale;
int _ApplyShadowOn;

sampler2D _MetallicMap; //metallicSmoothnessOcclusion,
sampler2D _HeightClothSSSMask;

float _Smoothness;
float _Metallic;
float _Occlusion;

float _Cutoff;

//-------------------------- detail map 
// detail map mode id
#define DETAIL_MAP_MODE_MULTIPLY 0
#define DETAIL_MAP_MODE_REPLACE 1
SamplerState tex_linear_repeat_sampler;

int _DetailMapOn;
int _DetailMapMode;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMap);
float _DetailMapIntensity;
float4 _DetailMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap);
float4 _DetailNormalMap_ST;
float _DetailNormalMapScale;
//Mouth
int _Detail1_MapOn;
int _Detail1_MapMode;
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail1_Map);
float _Detail1_MapIntensity;
float4 _Detail1_Map_ST;
//UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail1_NormalMap);
//float4 _Detail1_NormalMap_ST;
//float _Detail1_NormalMapScale;
//Eye
int _Detail2_MapOn;
int _Detail2_MapMode;
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail2_Map);
float _Detail2_MapIntensity;
float4 _Detail2_Map_ST;
//UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail2_NormalMap);
//float4 _Detail2_NormalMap_ST;
//float _Detail2_NormalMapScale;
//Eyebrow
int _Detail3_MapOn;
int _Detail3_MapMode;
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail3_Map);
float _Detail3_MapIntensity;
float4 _Detail3_Map_ST;
//UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail3_NormalMap);
//float4 _Detail3_NormalMap_ST;
//float _Detail3_NormalMapScale;
//Face
int _Detail4_MapOn;
int _Detail4_MapMode;
UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail4_Map);
float _Detail4_MapIntensity;
float4 _Detail4_Map_ST;
//UNITY_DECLARE_TEX2D_NOSAMPLER(_Detail4_NormalMap);
//float4 _Detail4_NormalMap_ST;
//float _Detail4_NormalMapScale;

//---------------------------- ibl
samplerCUBE _EnvCube;
float _EnvIntensity;
float3 _ReflectionOffsetDir;

sampler2D _EmissionMap;
float4 _EmissionColor;
float _Emission;
float _IndirectIntensity;

int _AlphaTestOn;
int _AlphaPreMultiply;

int _ClothOn;
float _ClothSpecWidthMin;
float _ClothSpecWidthMax;
int _ClothMaskOn;

// -------------------------------------- main light
#define MAX_SPECULAR 25
//---- 当前物体的光照
int _CustomLightOn;
fixed4 _LightDir;
fixed4 _LightColor;

float3 _MainLightDir;
float3 _MainLightColor;

int _SSSOn;
float3 _BackSSSColor,_FrontSSSColor;
float _FrontSSSIntensity,_BackSSSIntensity;

// ----------------- parallel
int _ParallalOn;
float _Height;

inline UnityLight GetLight(){
    #if !LIGHTMAP_ON
    float3 dir = _WorldSpaceLightPos0.xyz;
    float3 color = _LightColor0;
    #else
    float3 dir = _MainLightDir;
    float3 color = _MainLightColor;
    #endif

    // ---- 改变主光源,方向,颜色.
    dir.xyz += _CustomLightOn > 0 ? _LightDir.xyz : 0;
    color += _CustomLightOn > 0 ?_LightColor : 0;
    dir = normalize(dir);

    UnityLight l = {color.rgb,dir.xyz,0};
    return l;
}


inline float FastSSS(float3 l,float3 v){
    return saturate(dot(l,v));
}

inline float3 CalcSSS(float2 uv,float3 l,float3 v,float frontSSSMask,float backSSSMask){
    float sss1 = FastSSS(l,v);
    float sss2 = FastSSS(-l,v);
    float3 front = sss1 * _FrontSSSIntensity * frontSSSMask * _FrontSSSColor;
    float3 back = sss2 * _BackSSSIntensity * backSSSMask * _BackSSSColor;
    return (front + back);
}


inline float3 GetIndirectSpecular(float3 reflectDir,float rough){
    rough = rough *(1.7 - rough * 0.7);
    float mip = rough * 6;
    float4 rgbm = texCUBElod(_EnvCube,float4(reflectDir,mip));
    return DecodeHDR(rgbm,unity_SpecCube0_HDR);
}


inline half3 AlphaPreMultiply (half3 diffColor, half alpha, half oneMinusReflectivity, out half outModifiedAlpha)
{
    if(_AlphaPreMultiply){
        diffColor *= alpha;

        #if (SHADER_TARGET < 30)
            outModifiedAlpha = alpha;
        #else
            outModifiedAlpha = 1-oneMinusReflectivity + alpha*oneMinusReflectivity;
        #endif
    }else{
        outModifiedAlpha = alpha;
    }
    return diffColor;
}

inline float2 Parallax(float2 uv,float height,float3 viewTangentSpace){
    if(_ParallalOn){
        uv += ParallaxOffset(height,_Height,viewTangentSpace);
    }
    return uv;
}

//inline float3 CalcDetailNormal(Texture2D tex, float2 uv, float scale,float4 uvTilingOffset, float3 tn, float mask, bool isOn) {
//	if (isOn) {
//		float3 dtn = UnpackScaleNormal(tex.Sample(tex_linear_repeat_sampler,uv * uvTilingOffset.xy + uvTilingOffset.zw), scale);
//        dtn = normalize(float3(tn.xy+dtn.xy,tn.z*dtn.z));
//		tn = lerp(tn, dtn, mask);
//	}
//	return tn;
//}

inline float3 CalcNormal(float2 uv, float detailMask ){
    float3 tn = UnpackScaleNormal(tex2D(_NormalMap,uv),_NormalMapScale);
	
	if (_DetailMapOn) {
		float3 dtn = UnpackScaleNormal(_DetailNormalMap.Sample(tex_linear_repeat_sampler, uv * _DetailNormalMap_ST.xy + _DetailNormalMap_ST.zw), _DetailNormalMapScale);
		dtn = normalize(float3(tn.xy + dtn.xy, tn.z*dtn.z));
		tn = lerp(tn, dtn, detailMask);
	}
    return tn;
}


inline void ApplyDetailAlbedo(inout float4 mainColor, float3 detailMapColor,  float mask,bool isOn,int detailMapMode){
    if(isOn){
        //float3 detailAlbedo = tex2D(tex, uv);
		//float3 detailAlbedo=tex.Sample(tex_linear_repeat_sampler,uv);
		float3 detailAlbedo = detailMapColor;
        if(detailMapMode == DETAIL_MAP_MODE_MULTIPLY){
            mainColor.rgb *= lerp(1,detailAlbedo * unity_ColorSpaceDouble.rgb,mask);
        }else if(detailMapMode == DETAIL_MAP_MODE_REPLACE){
            mainColor.rgb = lerp(mainColor,detailAlbedo,mask);
        }
    }
    
}

inline float4 CalcAlbedo(float2 uv, 
    float3 detailMapCol, float3 detail1MapCol, float3 detail2MapCol, float3 detail3MapCol, float3 detail4MapCol,
    float detailMask, float detail1Mask,float detail2Mask, float detail3Mask, float detail4Mask) 
{

    float4 albedo = tex2D(_MainTex,uv) ;
    ApplyDetailAlbedo(albedo, detailMapCol, detailMask, _DetailMapOn,_DetailMapMode);
    ApplyDetailAlbedo(albedo, detail1MapCol, detail1Mask, _Detail1_MapOn,_Detail1_MapMode);
    ApplyDetailAlbedo(albedo, detail2MapCol, detail2Mask, _Detail2_MapOn,_Detail2_MapMode);
    // return albedo;
	ApplyDetailAlbedo(albedo, detail3MapCol, detail3Mask, _Detail3_MapOn, _Detail3_MapMode);
	ApplyDetailAlbedo(albedo, detail4MapCol, detail4Mask, _Detail4_MapOn, _Detail4_MapMode);
    return albedo * _Color;
}

inline UnityIndirect CalcGI(float3 albedo,float2 uv,float3 reflectDir,float3 normal,float occlusion,float roughness){
    float3 indirectSpecular = GetIndirectSpecular(reflectDir,roughness) * occlusion * _EnvIntensity * _IndirectIntensity;
    float3 indirectDiffuse = albedo * occlusion;
    indirectDiffuse += ShadeSH9(float4(normal,1));
    UnityIndirect indirect = {indirectDiffuse,indirectSpecular};
    return indirect;
}

inline float Pow4(float a){
    float a2 = a*a;
    return a2*a2;
}
inline float Pow5(float a){
    float a2 = a*a;
    return a2*a2*a;
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
    return (a2 * a2 * a2)/ (s * s);
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
    float sin2h = 1. - cos2h;
    return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI);
}

float AshikhminV(float ndotv, float ndotl)
{
    return 1. / (4. * (ndotl + ndotv - ndotl * ndotv));
}

inline float Cloth(float nv,float clothMask){
    float offset = smoothstep(_ClothSpecWidthMin,_ClothSpecWidthMax,nv);
    // float offsetMask = smoothstep(0.3,0.31,smoothness);
    return saturate(offset) * clothMask;
}

/**
    emission color : rgb
    emission Mask : a
*/
float3 CalcEmission(float3 albedo,float2 uv){
    float4 tex = tex2D(_EmissionMap,uv);
    return albedo * tex.rgb * tex.a * _Emission * _EmissionColor;
}

struct PBSData{
    float3 tangent;
    float3 binormal;
    float clothMask;
    bool isClothOn;
    bool isHairOn;
    float3 hairSpecColor;
};

inline float4 PBS(float3 diffColor,half3 specColor,float oneMinusReflectivity,float smoothness,
    float3 normal,float3 viewDir,
    UnityLight light,UnityIndirect gi,PBSData data){

    float a = 1- smoothness;
    float a2 = a*a;
    a2 = max(0.002,a2);
    
    float3 l = normalize(light.dir);
    float3 n = normalize(normal);
    float3 v = normalize(viewDir);
    float3 h = normalize(l + v);
    float3 t = normalize(data.tangent);
    float3 tb = normalize(data.binormal);

    float nh = saturate(dot(n,h));
    float nl = saturate(dot(n,l));
    float nv = abs(dot(n,v));
    float lv = saturate(dot(l,v));
    float lh = saturate(dot(l,h));

    if(data.isClothOn){
        float offset = Cloth(nv,data.clothMask);
        nh += offset;
        a2 = offset;
    }
    // -------------- diffuse part
    float diffuseTerm = DisneyDiffuse(nv,nl,lh,a) * nl;
    // float diffuseTerm = nl;
    float3 directDiffuse = light.color * diffuseTerm;
    float3 indirectDiffuse = gi.diffuse;
    float3 diffuse = (directDiffuse + indirectDiffuse) * diffColor;

    // -------------- specular part
    float3 F = FresnelTerm(specColor,lh);
    float3 specularTerm = (float3)0;

    if(data.isHairOn){
        specularTerm = data.hairSpecColor *nl;
    }else{
        // pbs specularTerm
        float V = SmithJointGGXTerm(nl,nv,a2);
        //float D = NDFBlinnPhongTerm(nh,RoughnessToSpecPower(a));
        float D = D_GGXTerm(nh,a2);

        // if(data.isClothOn){
        //     V = AshikhminV(nv,nl);
        //     D = CharlieD(a,nh);
        // }
        specularTerm = V * D * PI * nl;
    }

    specularTerm = max(0,specularTerm);
    specularTerm *= any(specColor)? 1 : 0;

    float surfaceReduction =1 /(a2 * a2+1);
    float grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

    float3 directSpecular = specularTerm * light.color * F;
    float3 indirecSpecular = surfaceReduction * gi.specular * FresnelLerpFast(specColor,grazingTerm,nv);
    float3 specular = directSpecular + indirecSpecular;
    return float4(diffuse + specular,1);
}

float4 CalcPBS(float3 diffColor,half3 specColor,float oneMinusReflectivity,float smoothness,
    float3 normal,float3 viewDir,
    UnityLight light,UnityIndirect gi,PBSData data){
        #if defined(PBS1)
            return PBS(diffColor,specColor,oneMinusReflectivity,smoothness,normal,viewDir,light,gi,data);
        #else
            return UNITY_BRDF_PBS(diffColor,specColor,oneMinusReflectivity,smoothness,normal,viewDir,light,gi);
        #endif
}
#endif // end of SIMPLE_PBS_CORE_CGINC