#if !defined (POWER_PBS_CORE_CGINC)
#define POWER_PBS_CORE_CGINC
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "PowerPBSData.cginc"
#include "BSDF.cginc"
#include "URP_Lighting.cginc"

inline UnityLight GetLight(){
    float3 dir = _MainLightPosition;
    float3 color = _MainLightColor;

    // ---- 改变主光源,方向,颜色.
    dir.xyz += _CustomLightOn > 0 ? _LightDir.xyz : 0;
    color += _CustomLightOn > 0 ?_LightColor : 0;
    dir = SafeNormalize(dir);

    UnityLight l = {color.rgb,dir.xyz,0};
    return l;
}

inline float3 CalcSSS(float3 l,float3 v,float2 fastSSSMask){
    float sss1 = FastSSS(l,v);
    float sss2 = FastSSS(-l,v);
    float3 front = sss1 * _FrontSSSIntensity * fastSSSMask.x * _FrontSSSColor;
    float3 back = sss2 * _BackSSSIntensity * fastSSSMask.y * _BackSSSColor;
    return (front + back);
}

inline float3 GetWorldViewDir(float3 worldPos){
    if(unity_OrthoParams.w != 0){ // ortho
        return -float3(UNITY_MATRIX_MV[0].z,UNITY_MATRIX_MV[1].z,UNITY_MATRIX_MV[2].z);
    }
    return UnityWorldSpaceViewDir(worldPos);
}

inline float3 PreScattering(float3 normal,float3 lightDir,float3 lightColor,float nl,float4 mainTex,float3 worldPos,float curveScale,float scatterIntensity){
    float wnl = dot(normal,(lightDir)) * 0.5 + 0.5;
    // float deltaNormal = length(fwidth(normal))*10;
    // float deltaPos = length(fwidth(worldPos));
    // float curvature = deltaNormal/1 * curveScale;
    float atten = 1-wnl;//smoothstep(0.,0.5,nl);
    float3 scattering = UNITY_SAMPLE_TEX2D(_ScatteringLUT,float2(wnl,curveScale ));
    return scattering * lightColor * mainTex.xyz * atten * scatterIntensity * mainTex.w;
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
	
	if (_Detail_MapOn) {
        float2 dnUV = uv * _Detail_NormalMap_ST.xy + _Detail_NormalMap_ST.zw;
		float3 dn = UnpackScaleNormal(SAMPLE_TEXTURE2D(_Detail_NormalMap,sampler_Detail_NormalMap, dnUV), _Detail_NormalMapScale);
		dn = normalize(float3(tn.xy + dn.xy, tn.z*dn.z));
		tn = lerp(tn, dn, detailMask);
	}
    return tn;
}


inline float CalcDetailAlbedo(inout float4 mainColor, TEXTURE2D(texObj),float2 uv, float detailIntensity,bool isOn,int detailMapMode){
    float detailMask = 0;
    if(isOn){
        float4 tex = SAMPLE_TEXTURE2D(texObj,sampler_linear_repeat,uv);
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

#define CALC_DETAIL_ALBEDO(id) CalcDetailAlbedo(albedo, _Detail##id##_Map,TRANSFORM_TEX(uv,_Detail##id##_Map), _Detail##id##_MapIntensity, _Detail##id##_MapOn,_Detail##id##_MapMode)

inline float4 CalcAlbedo(float2 uv,out float detailMask) 
{
    float4 albedo = UNITY_SAMPLE_TEX2D(_MainTex,uv) ;
    detailMask = CALC_DETAIL_ALBEDO();
    CALC_DETAIL_ALBEDO(1);
    CALC_DETAIL_ALBEDO(2);
    CALC_DETAIL_ALBEDO(3);
    CALC_DETAIL_ALBEDO(4);
    return albedo;
}

inline UnityIndirect CalcGI(float3 albedo,float2 uv,float3 reflectDir,float3 normal,float3 occlusion,float roughness){
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

#define PBR_MODE_STANDARD 0
#define PBR_MODE_ANISO 1
#define PBR_MODE_CLOTH 2
#define PBR_MODE_STRAND 3

inline float3 CalcSpeccularTerm(inout PBSData data,float nl,float nv,float nh,float lh,float th,float bh,float3 specColor,float roughness){
    float V = 1;
    float D = 0;
    float3 specTerm = 0;
    switch(_PBRMode){
        case PBR_MODE_STANDARD :
            specTerm = MinimalistCookTorrance(nh,lh,roughness);
            // V = SmithJointGGXTerm(nl,nv,roughness);
            // D = D_GGXTerm(nh,roughness);
            // specTerm = V * D * PI;
        break;
        case PBR_MODE_ANISO:
            // float tv = (dot(data.tangent,data.viewDir));
            // float tl = (dot(data.tangent,data.lightDir));
            // float bv = (dot(data.binormal,data.viewDir));
            // float bl = (dot(data.binormal,data.lightDir));

            float anisoRough = _AnisoRough * 0.5+0.5;
            // D = DV_SmithJointGGXAniso(th,bh,nh,tv,bv,nv,tl,bl,nl,anisoRough,1-anisoRough) ;
            V = SmithJointGGXTerm(nl,nv,roughness);
            D = D_GGXAniso(th,bh,nh,anisoRough,1-anisoRough);
            // D = D_WardAniso(nl,nv,nh,th,bh,anisoRough,1-anisoRough);
            specTerm = D * _AnisoIntensity * _AnisoColor;
            
            if(_AnisoLayer2On){
                anisoRough = _Layer2AnisoRough * 0.5+0.5;
                D = D_GGXAniso(th,bh,nh,anisoRough,1-anisoRough);
                // D = DV_SmithJointGGXAniso(th,bh,nh,tv,bv,nv,tl,bl,nl,anisoRough,1-anisoRough) ;
                specTerm += D * _Layer2AnisoIntensity * _Layer2AnisoColor;
            }
            specTerm *= V * PI;
            specTerm *= lerp(1,data.mainTex.a,_AnisoMaskUseMainTexA);
        break;
        case PBR_MODE_CLOTH:
            V = AshikhminV(nv,nl);
            D = CharlieD(roughness,nh);
            D = smoothstep(_ClothDMin,_ClothDMax,D);
            float3 sheenColor = _ClothSheenColor;
            // extra calc ggx
            if(_ClothGGXUseMainTexA){
                sheenColor = lerp(sheenColor,1,data.mainTex.a);
                float3 DF = D_GGXTerm(nh,roughness) * FresnelTerm(specColor,lh);
                D = lerp(D*2,DF,data.mainTex.a);
            }
            specTerm = V * D * PI * sheenColor ;
        break;
        case PBR_MODE_STRAND:
            specTerm = data.hairSpecColor;
        break;
    }
    specTerm = max(0,specTerm * nl);
    specTerm *= any(specColor)? 1 : 0;
    // calc F
    float3 F =1;
    if(_PBRMode != PBR_MODE_CLOTH )
        F = FresnelTerm(specColor,lh) * _FresnelIntensity;

    specTerm *= F;
    return specTerm;
}

float CalcDiffuseTerm(float nl,float nv,float lh,float a){
    float diffuseTerm = 0;
    // if(_PBRMode != PBR_MODE_CLOTH)
        diffuseTerm = DisneyDiffuse(nv,nl,lh,a) * nl;
    return diffuseTerm;
}

float3 CalcIndirect(UnityIndirect gi,float3 diffColor,float3 specColor,float smoothness,float a2,float oneMinusReflectivity,float nv){
    float3 indirectDiffuse = gi.diffuse * diffColor;

    float surfaceReduction =1 /(a2 * a2 + 1); // [1,0.5]z
    float grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity)); //smoothness + metallic
    float3 indirectSpecular = surfaceReduction * gi.specular * FresnelLerpFast(specColor,grazingTerm,nv);
    float3 color = indirectDiffuse + indirectSpecular;
    return color;
}

float3 CalcDirect(inout PBSData data,float3 diffColor,half3 specColor,float3 lightColor,
    float nl,float nv,float nh,float lh,float th,float bh,float a,float a2){

    float diffuseTerm = CalcDiffuseTerm(nl,nv,lh,a);
    float3 specularTerm = 0;
    if(_SpecularOn){
        specularTerm = CalcSpeccularTerm(data,nl,nv,nh,lh,th,bh,specColor,a2);
    }
    float3 color = diffuseTerm * diffColor + specularTerm;
    color *= lightColor;
    return color;
}

#define CALC_LIGHT_INFO(lightDir)\
    float3 l = SafeNormalize(lightDir);\
    float3 v = (data.viewDir);\
    float3 h = SafeNormalize(l + v);\
    float3 t = (data.tangent);\
    float3 b = (data.binormal);\
    float3 n = (data.normal);\
    float nh = saturate(dot(n,h));\
    float nl = saturate(dot(n,l));\
    float nv = saturate(dot(n,v));\
    float lv = saturate(dot(l,v));\
    float lh = saturate(dot(l,h));\
    float th = dot(t,h);\
    float bh = dot(b,h)

inline float3 CalcAdditionalLight(PBSData data,float3 diffColor,float3 specColor,Light light,float a,float a2){
    CALC_LIGHT_INFO(light.direction);
    float lightAtten = light.distanceAttenuation * light.shadowAttenuation;
    return CalcDirect(data/**/,diffColor,specColor,light.color,nl,nv,nh,lh,th,bh,a,a2) * lightAtten;
}

inline float4 PBS(float3 diffColor,half3 specColor,UnityLight mainLight,UnityIndirect gi,inout PBSData data){
    // perceptualRoughness,roughness
    float a = max(1- data.smoothness,HALF_MIN_SQRT);
    float a2 = max(a*a,HALF_MIN);

    CALC_LIGHT_INFO(mainLight.dir);

    // set pbsdata for others flow.
    data.nl = nl;
    data.nv = nv;
    data.lightDir = l;
    data.halfDir = h;

    float3 color = CalcIndirect(gi,diffColor,specColor,data.smoothness,a2,data.oneMinusReflectivity,nv);
return color.xyzx;    
    color += CalcDirect(data/**/,diffColor,specColor,mainLight.color,nl,nv,nh,lh,th,bh,a,a2);
    
    if(_ClearCoatOn){
        color += CalcDirect(data/**/,0,_ClearCoatSpecColor,mainLight.color,nl,nv,nh,lh,th,bh,a,a2);
        // return CalcDirect(data/**/,0,_ClearCoatSpecColor,mainLight.color,nl,nv,nh,lh,th,bh,a,a2).xyzx;
    }
// return CalcDirect(data/**/,diffColor,specColor,mainLight.color,nl,nv,nh,lh,th,bh,a,a2).xyzx;
    if(_ReceiveAdditionalLightsOn){
        int lightCount = GetAdditionalLightsCount();
        for(int lightId = 0 ; lightId <lightCount;lightId++){
            Light light1 = GetAdditionalLight(lightId,data.worldPos);
            color += CalcAdditionalLight(data/**/,diffColor,specColor,light1,a,a2);
            if(_ScatteringLUTOn && _AdditionalLightCalcScatter){
                float3 scatteredColor = PreScattering(data.normal,light1.direction,light1.color,data.nl,data.mainTex,data.worldPos,_CurvatureScale,_ScatteringIntensity);
                color.rgb += scatteredColor ;
            }
            if(_SSSOn && _AdditionalLightCalcFastSSS){
                color.rgb += CalcSSS(light1.direction,data.viewDir,data.heightClothFastSSSMask.zw);
            }
        }
    }

    return float4(color,1);
}

float4 CalcPBS(float3 diffColor,half3 specColor,float oneMinusReflectivity,float smoothness,
    UnityLight light,UnityIndirect gi,inout PBSData data){
        // #if defined(PBS1)
            return PBS(diffColor,specColor,light,gi,data);
        // #else
        //     return UNITY_BRDF_PBS(diffColor,specColor,data.oneMinusReflectivity,data.smoothness,data.normal,data.viewDir,light,gi);
        // #endif
}


void ApplyVertexWave(inout float4 vertex,float3 normal,float4 vertexColor){
    vertex.xyz += _VertexScale * vertexColor.x * normal;
}
#endif // end of POWER_PBS_CORE_CGINC