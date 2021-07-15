// Upgrade NOTE: replaced 'defined SIMPLE_PBS_CORE_CGINC' with 'defined (SIMPLE_PBS_CORE_CGINC)'

#if !defined (SIMPLE_PBS_CORE_CGINC)
#define SIMPLE_PBS_CORE_CGINC
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "PowerPBSData.cginc"
#include "BSDF.cginc"


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

inline float3 CalcSSS(float2 uv,float3 l,float3 v,float frontSSSMask,float backSSSMask){
    float sss1 = FastSSS(l,v);
    float sss2 = FastSSS(-l,v);
    float3 front = sss1 * _FrontSSSIntensity * frontSSSMask * _FrontSSSColor;
    float3 back = sss2 * _BackSSSIntensity * backSSSMask * _BackSSSColor;
    return (front + back);
}

inline float3 GetWorldViewDir(float3 worldPos){
    if(unity_OrthoParams.w != 0){ // ortho
        return -float3(UNITY_MATRIX_MV[0].z,UNITY_MATRIX_MV[1].z,UNITY_MATRIX_MV[2].z);
    }
    return UnityWorldSpaceViewDir(worldPos);
}

inline float3 PreScattering(float3 normal,UnityLight light,float nl,float4 mainTex,float3 worldPos,float curveScale,float scatterIntensity){
    float wrappedNL = dot(normal,light.dir) * 0.5 + 0.5;
    // float deltaNormal = length(fwidth(normal));
    // float deltaPos = length(fwidth(worldPos));
    // float curvature = deltaNormal/1 * curveScale;
    float atten = smoothstep(0.,0.3,nl) * (1 - wrappedNL);
    float3 scattering = UNITY_SAMPLE_TEX2D(_ScatteringLUT,float2(wrappedNL,mainTex.a * curveScale));
    return scattering * light.color * mainTex.xyz * atten * scatterIntensity;
}

inline float3 GetIndirectSpecular(float3 reflectDir,float rough){
    rough = rough *(1.7 - rough * 0.7);
    float mip = rough * 6;

    float4 encodeIrradiance = 0;
    if(_CustomIBLOn){
        encodeIrradiance = UNITY_SAMPLE_TEXCUBE_LOD(_EnvCube,reflectDir,mip);
        encodeIrradiance *= _EnvIntensity;
    }else{
        encodeIrradiance = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, mip);
    }
    return DecodeHDR(encodeIrradiance,unity_SpecCube0_HDR);
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



inline float3 CalcNormal(float2 uv, float detailMask ){
    float3 tn = UnpackScaleNormal(UNITY_SAMPLE_TEX2D(_NormalMap,uv),_NormalMapScale);
	
	if (_DetailMapOn) {
		float3 dtn = UnpackScaleNormal(_DetailNormalMap.Sample(tex_linear_repeat_sampler, uv * _DetailNormalMap_ST.xy + _DetailNormalMap_ST.zw), _DetailNormalMapScale);
		dtn = normalize(float3(tn.xy + dtn.xy, tn.z*dtn.z));
		tn = lerp(tn, dtn, detailMask);
	}
    return tn;
}


inline float CalcDetailAlbedo(inout float4 mainColor, UNITY_DECLARE_TEX2D_NOSAMPLER(texObj),float2 uv, float detailIntensity,bool isOn,int detailMapMode){
    float detailMask = 0;
    if(isOn){
        float4 tex = texObj.Sample(tex_linear_repeat_sampler,uv);
		float3 detailAlbedo = tex.xyz;
        detailMask = tex.w;
        float mask = detailMask * detailIntensity;
        if(detailMapMode == DETAIL_MAP_MODE_MULTIPLY){
            mainColor.rgb *= lerp(1,detailAlbedo * unity_ColorSpaceDouble.rgb,mask);
        }else if(detailMapMode == DETAIL_MAP_MODE_REPLACE){
            mainColor.rgb = lerp(mainColor,detailAlbedo,mask);
        }
    }
    return detailMask;
}

inline float4 CalcAlbedo(float2 uv,out float detailMask) 
{
    float4 albedo = UNITY_SAMPLE_TEX2D(_MainTex,uv) ;
    detailMask = CalcDetailAlbedo(albedo, _DetailMap,TRANSFORM_TEX(uv,_DetailMap), _DetailMapIntensity, _DetailMapOn,_DetailMapMode);
    CalcDetailAlbedo(albedo, _Detail1_Map,TRANSFORM_TEX(uv,_Detail1_Map), _Detail1_MapIntensity, _Detail1_MapOn,_Detail1_MapMode);
    CalcDetailAlbedo(albedo, _Detail2_Map,TRANSFORM_TEX(uv,_Detail2_Map), _Detail2_MapIntensity, _Detail2_MapOn,_Detail2_MapMode);
	CalcDetailAlbedo(albedo, _Detail3_Map,TRANSFORM_TEX(uv,_Detail3_Map), _Detail3_MapIntensity, _Detail3_MapOn, _Detail3_MapMode);
	CalcDetailAlbedo(albedo, _Detail4_Map,TRANSFORM_TEX(uv,_Detail4_Map), _Detail4_MapIntensity, _Detail4_MapOn, _Detail4_MapMode);
    return albedo * _Color;
}

inline UnityIndirect CalcGI(float3 albedo,float2 uv,float3 reflectDir,float3 normal,float occlusion,float roughness){
    float3 indirectSpecular = GetIndirectSpecular(reflectDir,roughness) * occlusion * _IndirectIntensity;
    // float3 indirectDiffuse = albedo * occlusion;
    // indirectDiffuse += ShadeSH9(float4(normal,1));
    float3 indirectDiffuse = ShadeSH9(float4(normal,1)) * occlusion;
    UnityIndirect indirect = {indirectDiffuse,indirectSpecular};
    return indirect;
}


/**
    emission color : rgb
    emission Mask : a
*/
float3 CalcEmission(float3 albedo,float2 uv){
    float4 tex = UNITY_SAMPLE_TEX2D(_EmissionMap,uv);
    return albedo * tex.rgb * tex.a * _Emission * _EmissionColor;
}


inline float4 PBS(float3 diffColor,half3 specColor,float oneMinusReflectivity,float smoothness,
    float3 normal,float3 viewDir,
    UnityLight light,UnityIndirect gi,inout PBSData data){

    // perceptualRoughness,roughness
    float a = max(1- smoothness,HALF_MIN_SQRT);
    float a2 = max(a*a,HALF_MIN);
    
    float3 l = normalize(light.dir);
    float3 n = normalize(normal);
    float3 v = normalize(viewDir);
    float3 h = normalize(l + v);
    float3 t = normalize(data.tangent);
    float3 b = normalize(data.binormal);

    float nh = saturate(dot(n,h));
    float nl = saturate(dot(n,l));
    float nv = abs(dot(n,v));
    float lv = saturate(dot(l,v));
    float lh = saturate(dot(l,h));
    float th = 0;
    float bh = 0;
    

    // set pbsdata for others flow.
    data.nl = nl;

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
        float D = 0;

        // calc D
        if(data.isAnisoOn){
            th = dot(t,h);
            bh = dot(b,h);
            // V = AshikhminV(nv,nl);
            // D += CharlieD(a,nh);
            D = D_GGXAniso(th,bh,nh,_RoughT,_RoughB) * _AnisoIntensity;
            if(data.isAnisoLayer2On){
                D += D_GGXAniso(th,bh,nh,_Layer2RoughT,_Layer2RoughB) * _Layer2AnisoIntensity;
            }
        }else{
            D = D_GGXTerm(nh,a2);
        }
        specularTerm = V * D * PI * nl;
    }
    specularTerm = max(0,specularTerm);
    specularTerm *= any(specColor)? 1 : 0;

    float surfaceReduction =1 /(a2 * a2+1); // [1,0.5]
    float grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity)); //smoothness + metallic
    float3 indirectSpecular = surfaceReduction * gi.specular * FresnelLerpFast(specColor,grazingTerm,nv);
    
    float3 directSpecular = specularTerm * light.color * F;
    float3 specular = directSpecular + indirectSpecular;
    return float4(diffuse + specular,1);
}

float4 CalcPBS(float3 diffColor,half3 specColor,float oneMinusReflectivity,float smoothness,
    float3 normal,float3 viewDir,
    UnityLight light,UnityIndirect gi,inout PBSData data){
        #if defined(PBS1)
            return PBS(diffColor,specColor,oneMinusReflectivity,smoothness,normal,viewDir,light,gi,data);
        #else
            return UNITY_BRDF_PBS(diffColor,specColor,oneMinusReflectivity,smoothness,normal,viewDir,light,gi);
        #endif
}
#endif // end of SIMPLE_PBS_CORE_CGINC