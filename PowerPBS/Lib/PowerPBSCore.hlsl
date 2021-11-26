#if !defined (POWER_PBS_CORE_HLSL)
#define POWER_PBS_CORE_HLSL
#include "UnityLib/UnityLightingCommon.hlsl"
#include "PowerPBSData.hlsl"
#include "BSDF.hlsl"
#include "CommonUtils.hlsl"
#include "URP_Lighting.hlsl"
#include "ExtractLightFromSH.hlsl"

inline UnityLight GetLight(){
    float3 dir = _MainLightPosition;
    float3 color = _MainLightColor;

    // ---- 改变主光源,方向,颜色.
    dir.xyz += _CustomLightOn > 0 ? _LightDir.xyz : 0;
    color += _CustomLightOn > 0 ?_LightColor : 0;
    dir = (dir);

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
    float3 dir = 0;
    if(unity_OrthoParams.w != 0){ // ortho
        // dir = -float3(UNITY_MATRIX_MV[0].z,UNITY_MATRIX_MV[1].z,UNITY_MATRIX_MV[2].z);
        dir = -UNITY_MATRIX_V[2].xyz;
    }else
        dir = UnityWorldSpaceViewDir(worldPos);
    return dir;
}

inline float3 PreScattering(float3 normal,float3 lightDir,float3 lightColor,float nl,float4 mainTex,float3 worldPos,float curveScale,float scatterIntensity){
    float wnl = dot(normal,(lightDir)) * 0.5 + 0.5;
    // float deltaNormal = length(fwidth(normal))*10;
    // float deltaPos = length(fwidth(worldPos));
    // float curvature = deltaNormal/1 * curveScale;
    float atten = 1-wnl;//smoothstep(0.,0.5,nl);
    float3 scattering = SAMPLE_TEXTURE2D(_ScatteringLUT,sampler_linear_repeat,float2(wnl,curveScale ));
    float scatterMask = lerp(1,mainTex.w,_PreScatterMaskUseMainTexA);
    return scattering * lightColor * mainTex.xyz * atten * scatterIntensity * scatterMask;
}

inline float3 GetIndirectSpecular(float3 reflectDir,float rough){
    rough = rough *(1.7 - rough * 0.7);
    float mip = rough * 6;

    float4 encodeIrradiance = 0;
    if(_CustomIBLOn){
        encodeIrradiance = SAMPLE_TEXTURECUBE_LOD(_EnvCube,sampler_linear_repeat,reflectDir,mip);
        encodeIrradiance *= _EnvIntensity;
    }else{
        encodeIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,sampler_linear_repeat, reflectDir, mip);
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
    float3 tn = UnpackScaleNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv),_NormalMapScale);
	
	if (_Detail_MapOn) {
        float2 dnUV = uv * _Detail_NormalMap_ST.xy + _Detail_NormalMap_ST.zw;
		float3 dn = UnpackScaleNormal(SAMPLE_TEXTURE2D(_Detail_NormalMap,sampler_linear_repeat, dnUV), _Detail_NormalMapScale);
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
    float4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv) ;
    detailMask = CALC_DETAIL_ALBEDO();
    CALC_DETAIL_ALBEDO(1);
    // CALC_DETAIL_ALBEDO(2);
    // CALC_DETAIL_ALBEDO(3);
    // CALC_DETAIL_ALBEDO(4);
    return albedo;
}

inline UnityIndirect CalcGI(float3 albedo,float2 uv,float3 reflectDir,float3 normal,float3 occlusion,float roughness){
    float3 indirectSpecular = GetIndirectSpecular(reflectDir,roughness) * occlusion * _IndirectSpecularIntensity;
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
    float4 tex = SAMPLE_TEXTURE2D(_EmissionMap,sampler_linear_repeat,uv);
    return albedo * tex.rgb * tex.a * _Emission * _EmissionColor;
}

#define PBR_MODE_STANDARD 0
#define PBR_MODE_ANISO 1
#define PBR_MODE_CLOTH 2
#define PBR_MODE_STRAND 3

inline float3 CalcSpecularTermOnlyStandard(inout PBSData data,float nl,float nv,float nh,float lh,float th,float bh,float3 specColor){
    // float3 specTerm = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2);
    float3 specTerm = D_GGXTerm(nh,data.roughness2);
    specTerm *= specColor;
    return specTerm;
}

inline float3 CalcSpecularTerm(inout PBSData data,float nl,float nv,float nh,float lh,float th,float bh,float3 specColor){
    float V = 1;
    float D = 0;
    float3 specTerm = 0;
    switch(_PBRMode){
        case PBR_MODE_STANDARD :
            // specTerm = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2);
            specTerm = D_GGXTerm(nh,data.roughness2);
            specTerm *= specColor;
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
            // V = SmithJointGGXTerm(nl,nv,data.roughness);
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
            D = CharlieD(data.roughness,nh);
            D = smoothstep(_ClothDMin,_ClothDMax,D);
            float3 sheenColor = _ClothSheenColor;
            // extra calc ggx
            if(_ClothGGXUseMainTexA){
                sheenColor = lerp(sheenColor,1,data.mainTex.a);
                float3 DF = D_GGXTerm(nh,data.roughness);// * FresnelTerm(specColor,lh);
                D = lerp(D*2,DF,data.mainTex.a);
            }
            specTerm = V * D * PI * sheenColor ;
        break;
        case PBR_MODE_STRAND:
            specTerm = data.hairSpecColor;
        break;
    }
    // specTerm = max(0,specTerm * nl);
    // specTerm *= any(specColor)? 1 : 0;
    // calc F
    // float3 F =1;
    // if(_PBRMode != PBR_MODE_CLOTH && _PBRMode != PBR_MODE_STANDARD)
    //     F = FresnelTerm(specColor,lh);

    // specTerm *= F;

    specTerm = min(specTerm, _MaxSpecularIntensity); // eliminate large value in HDR
    return specTerm;
}

float3 CalcIndirect(float smoothness,float roughness2,float oneMinusReflectivity,float3 giDiffColor,float3 giSpecColor,float3 diffColor,float3 specColor,float fresnelTerm){
    float3 indirectDiffuse = giDiffColor * diffColor;
    float surfaceReduction =1 /(roughness2 + 1); // [1,0.5]
    float grazingTerm = saturate(smoothness + 1 - oneMinusReflectivity) * _FresnelIntensity; //smoothness + metallic
    float3 indirectSpecular = surfaceReduction * giSpecColor * lerp(specColor,grazingTerm,fresnelTerm);
    return indirectDiffuse + indirectSpecular;
}

float3 CalcIndirect(PBSData data,float3 giDiffColor,float3 giSpecColor,float3 diffColor,float3 specColor,float fresnelTerm){
    return CalcIndirect(data.smoothness,data.roughness2,data.oneMinusReflectivity,giDiffColor,giSpecColor,diffColor,specColor,fresnelTerm);
}

float3 CalcIndirectApplyClearCoat(float3 indirectColor,ClearCoatData data,float fresnelTerm){
    float3 coatSpecGI = GetIndirectSpecular(data.reflectDir,data.perceptualRoughness) * data.occlusion * _CoatIndirectSpecularIntensity;
    float3 coatColor = CalcIndirect(data.smoothness,data.roughness2,1-data.oneMinusReflectivity,0,coatSpecGI,0,data.specColor,fresnelTerm); // 1-data.oneMinusReflectivity approach unity_ColorSpaceDielectricSpec.x(0.04) 
    float coatFresnel = unity_ColorSpaceDielectricSpec.x + unity_ColorSpaceDielectricSpec.w * fresnelTerm;
    return indirectColor * (1 - coatFresnel) + coatColor;
}

float3 CalcDirect(inout PBSData data,float3 diffColor,half3 specColor,float nl,float nv,float nh,float lh,float th,float bh){
    // float3 diffuseTerm = DisneyDiffuse(nl,nv,lh,data.roughness2) * diffColor;
    float3 diffuseTerm = diffColor;
    float3 specularTerm = 0;
    if(_SpecularOn){
        specularTerm = CalcSpecularTerm(data,nl,nv,nh,lh,th,bh,specColor);
    }
    return diffuseTerm + specularTerm;
}

float3 CalcDirectApplyClearCoat(float3 directColor,ClearCoatData data,float fresnelTerm,float nl,float nh,float lh){
    float3 specColor = 0;
    if(_SpecularOn){
        float3 coatSpec = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2) * data.specColor;
        float coatFresnel = kDielectricSpec.x + kDielectricSpec.a * fresnelTerm;
        // return directColor * 1;
        specColor = directColor * (1-coatFresnel) + coatSpec;
    }
    return specColor;
}

#define CALC_LIGHT_INFO(lightDir)\
    float3 l = (lightDir);\
    float3 v = (data.viewDir);\
    float3 h = SafeNormalize(l + v);\
    float3 t = (data.tangent);\
    float3 b = (data.binormal);\
    float3 n = SafeNormalize(data.normal);\
    float nh = saturate(dot(n,h));\
    float nl = saturate(dot(n,l));\
    float nv = saturate(dot(n,v));\
    float lv = saturate(dot(l,v));\
    float lh = saturate(dot(l,h));\
    float th = dot(t,h);\
    float bh = dot(b,h)

inline float3 CalcDirectAdditionalLight(PBSData data,float3 diffColor,float3 specColor,Light light){
    CALC_LIGHT_INFO(light.direction);
    float lightAtten = light.distanceAttenuation * light.shadowAttenuation;
    // float3 directColor = CalcDirect(data/**/,diffColor,specColor,nl,nv,nh,lh,th,bh);
    float3 directColor = diffColor;
    if(_SpecularOn){
        directColor += CalcSpecularTermOnlyStandard(data,nl,nv,nh,lh,th,bh,specColor);
    }
    return lightAtten *nl * light.color * directColor;
}

float3 CalcPBSAdditionalLight(inout PBSData data,float3 diffColor,float3 specColor){
    float3 color = 0;
    if(_ReceiveAdditionalLightsOn){
        int lightCount = GetAdditionalLightsCount();
        for(int lightId = 0 ; lightId <lightCount;lightId++){
            Light light1 = GetAdditionalLight(lightId,data.worldPos);
            
            color += CalcDirectAdditionalLight(data/**/,diffColor,specColor,light1);
            if(_ScatteringLUTOn && _AdditionalLightCalcScatter){
                float3 scatteredColor = PreScattering(data.normal,light1.direction,light1.color,data.nl,data.mainTex,data.worldPos,_CurvatureScale,_ScatteringIntensity);
                color.rgb += scatteredColor ;
            }
            if(_SSSOn && _AdditionalLightCalcFastSSS){
                color.rgb += CalcSSS(light1.direction,data.viewDir,data.heightClothFastSSSMask.zw);
            }
        }
    }
    return color;
}

float3 CalcIndirectApplySHDirLight(float3 indirectColor,PBSData data,float3 diffColor,float3 specColor){
    if (_DirectionalLightFromSHOn  && HasLightProbe() > 0)
    {
        Light light = GetDirLightFromUnityLightProbe();
        float3 lightColor = CalcDirectAdditionalLight(data, diffColor, specColor, light);
        indirectColor = indirectColor * rcp(1 + _AmbientSHIntensity)  + _DirectionalSHIntensity*lightColor; // orignal sh lighting as ambient
    }
    return indirectColor;
}

float4 CalcPBS(float3 diffColor,half3 specColor,UnityLight mainLight,UnityIndirect gi,ClearCoatData coatData,inout PBSData data){
    CALC_LIGHT_INFO(mainLight.dir);

    // set pbsdata for others flow.
    data.nl = nl;
    data.nv = nv;
    data.lightDir = l;
    data.halfDir = h;

    data.fresnelTerm = Pow4(1-nv);
    // indirect
    float3 color = CalcIndirect(data,gi.diffuse,gi.specular,diffColor,specColor,data.fresnelTerm );
    if(_ClearCoatOn){
        color = CalcIndirectApplyClearCoat(color,coatData,data.fresnelTerm );
    }
    // apply sh dir light
    color = CalcIndirectApplySHDirLight(color,data,diffColor,specColor);

    // back face gi compensate.
    color += (1-nl) * _BackFaceGIDiffuse * diffColor;

    // direct
    float3 directColor = CalcDirect(data/**/,diffColor,specColor,nl,nv,nh,lh,th,bh);
    if(_ClearCoatOn){
        directColor = CalcDirectApplyClearCoat(directColor,coatData/**/,data.fresnelTerm ,nl,nh,lh).xyzx;
    }
    // apply main light atten 
    directColor *= mainLight.color * nl;
    color += directColor;

    // additional lights
    color += CalcPBSAdditionalLight(data/**/,diffColor,specColor);

    return float4(color,1);
}

void ApplyVertexWave(inout float4 vertex,float3 normal,float4 vertexColor){
    vertex.xyz += _VertexScale * vertexColor.x * normal;
}

float3 CalcDiffuseAndSpecularFromMetallic(float3 albedo,float metallic,inout float3 specColor,out float oneMinusReflectivity){
    specColor = lerp(unity_ColorSpaceDielectricSpec.rgb,albedo,metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}

float ReflectivitySpecular(float3 specColor){
    return max(max(specColor.x,specColor.y),specColor.z);
}

void InitSurfaceData(float2 uv,float3 albedo,float alpha,float metallic,out SurfaceData data){
    // --- specular map flow
    if(_CustomSpecularMapOn){
        float2 specUV = TRANSFORM_TEX(uv,_CustomSpecularMap);
        float4 customSpecColor = SAMPLE_TEXTURE2D(_CustomSpecularMap,sampler_linear_repeat,specUV);
        data.specColor = lerp(unity_ColorSpaceDielectricSpec.xyz,customSpecColor.xyz,_Metallic) * customSpecColor.w * _CustomSpecularIntensity;
        data.oneMinusReflectivity = 1.0 - ReflectivitySpecular(data.specColor);
        data.diffColor = albedo * (1 - data.specColor);
    }else{
        // metallic flow
        data.diffColor = DiffuseAndSpecularFromMetallic (albedo, metallic, /*inout*/ data.specColor, /*out*/ data.oneMinusReflectivity);
    }
    
    data.diffColor = AlphaPreMultiply (data.diffColor, alpha, data.oneMinusReflectivity, /*out*/ data.finalAlpha);
}

void InitWorldData(float2 uv,float detailMask,float4 tSpace0,float4 tSpace1,float4 tSpace2,out WorldData data ){
    float2 normalMapUV = TRANSFORM_TEX(uv, _NormalMap);
    float3 tn = CalcNormal(normalMapUV,detailMask);
    data.normal = (float3(
        dot(tSpace0.xyz,tn),
        dot(tSpace1.xyz,tn),
        dot(tSpace2.xyz,tn)
    ));
    data.pos = float3(tSpace0.w,tSpace1.w,tSpace2.w);
    data.view = (GetWorldViewDir(data.pos));
    data.reflect = (reflect(-data.view + _ReflectionOffsetDir.xyz,data.normal));

    data.vertexNormal = (float3(tSpace0.z,tSpace1.z,tSpace2.z));
    data.tangent = (cross(data.normal,float3(0,1,0)));
    data.binormal = (cross(data.tangent,data.normal));
    // data.tangent = (float3(tSpace0.x,tSpace1.x,tSpace2.x));
    // data.binormal = (float3(tSpace0.y,tSpace1.y,tSpace2.y));
}

#endif // end of POWER_PBS_CORE_HLSL