#if !defined (POWER_PBS_CORE_HLSL)
#define POWER_PBS_CORE_HLSL
#include "UnityLib/UnityLightingCommon.hlsl"
#include "PowerPBSData.hlsl"
#include "Tools/BSDF.hlsl"
#include "Tools/CommonUtils.hlsl"
#include "UrpLib/URP_Lighting.hlsl"
#include "Tools/ExtractLightFromSH.hlsl"

inline UnityLight GetLight(){
    half3 dir = _MainLightPosition.xyz;
    half3 color = _MainLightColor.xyz;

    // ---- 改变主光源,方向,颜色.
    dir.xyz += _CustomLightOn > 0 ? _LightDir.xyz : 0;
    color += _CustomLightOn > 0 ?_LightColor.xyz : 0;
    dir = normalize(dir);

    UnityLight l = {color.rgb,dir.xyz,0};
    return l;
}

inline half3 CalcSSS(half3 l,half3 v,half2 fastSSSMask){
    half sss1 = FastSSS(l,v);
    half sss2 = FastSSS(-l,v);
    half3 front = sss1 * _FrontSSSIntensity * fastSSSMask.x * _FrontSSSColor;
    half3 back = sss2 * _BackSSSIntensity * fastSSSMask.y * _BackSSSColor;
    return (front + back);
}

inline half3 GetWorldViewDir(half3 worldPos){
    half3 dir = 0;
    if(unity_OrthoParams.w != 0){ // ortho
        // dir = half3(UNITY_MATRIX_MV[0].z,UNITY_MATRIX_MV[1].z,UNITY_MATRIX_MV[2].z);
        dir = UNITY_MATRIX_V[2].xyz;
    }else
        dir = UnityWorldSpaceViewDir(worldPos);
    return dir;
}

inline half3 PreScattering(half3 normal,half3 lightDir,half3 lightColor,half nl,half4 mainTex,half3 worldPos,half curveScale,half scatterIntensity,half3 maskData){
    half wnl = dot(normal,(lightDir)) * 0.5 + 0.5;
    // half deltaNormal = length(fwidth(normal))*10;
    // half deltaPos = length(fwidth(worldPos));
    // half curvature = deltaNormal/1 * curveScale;
    half atten = 1-wnl;//smoothstep(0.,0.5,nl);
    half4 scattering = SAMPLE_TEXTURE2D(_ScatteringLUT,sampler_linear_repeat,half2(wnl,curveScale ));

    half mask = GetMaskForIntensity(maskData,_PreScatterMaskFrom,_PreScatterMaskUsage,PRESSS_MASK_FOR_INTENSITY);

    return scattering.xyz * lightColor * mainTex.xyz * atten * scatterIntensity * mask;
}

inline half3 GetIndirectSpecular(half3 reflectDir,half rough){
    rough = rough *(1.7 - rough * 0.7);
    half mip = rough * 6;

    half4 encodeIrradiance = 0;
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

inline half3 CalcNormal(half2 uv, half detailMask ){
    half3 tn = UnpackScaleNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv),_NormalMapScale);
	
	// if (_Detail_MapOn) {
    #if defined(_DETAIL_MAP)
        half2 dnUV = uv * _Detail_NormalMap_ST.xy + _Detail_NormalMap_ST.zw;
		half3 dn = UnpackScaleNormal(SAMPLE_TEXTURE2D(_Detail_NormalMap,sampler_linear_repeat, dnUV), _Detail_NormalMapScale);
		dn = normalize(half3(tn.xy + dn.xy, tn.z*dn.z));
		tn = lerp(tn, dn, detailMask);
	// }
    #endif
    return tn;
}

inline half CalcDetailAlbedo(inout half4 mainColor, TEXTURE2D(texObj),half2 uv, half detailIntensity,bool isOn,int detailMapMode){
    half detailMask = 0;
    if(isOn){
        half4 tex = SAMPLE_TEXTURE2D(texObj,sampler_linear_repeat,uv);
		half3 detailAlbedo = tex.xyz;
        detailMask = tex.w;
        half mask = detailMask * detailIntensity;
        if(detailMapMode == DETAIL_MAP_MODE_MULTIPLY){
            mainColor.rgb *= lerp(1,detailAlbedo * unity_ColorSpaceDouble.rgb,mask);
        }else if(detailMapMode == DETAIL_MAP_MODE_REPLACE){
            mainColor.rgb = lerp(mainColor.xyz,detailAlbedo,mask);
        }
    }
    return detailMask;
}

#define CALC_DETAIL_ALBEDO(id) CalcDetailAlbedo(albedo, _Detail##id##_Map,TRANSFORM_TEX(uv,_Detail##id##_Map), _Detail##id##_MapIntensity, _Detail##id##_MapOn,_Detail##id##_MapMode)

inline half4 CalcAlbedo(half2 uv,out half detailMask) 
{
    detailMask = 1;
    half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv) ;
    #if defined(_DETAIL_MAP)
        detailMask = CALC_DETAIL_ALBEDO();
        CALC_DETAIL_ALBEDO(1);
        // CALC_DETAIL_ALBEDO(2);
        // CALC_DETAIL_ALBEDO(3);
        // CALC_DETAIL_ALBEDO(4);
    #endif
    return albedo;
}

inline UnityIndirect CalcGI(half3 albedo,half2 uv,half3 reflectDir,half3 normal,half3 occlusion,half roughness){
    half3 indirectSpecular = GetIndirectSpecular(reflectDir,roughness) * occlusion * _IndirectSpecularIntensity;
    // half3 indirectDiffuse = albedo * occlusion;
    // indirectDiffuse += ShadeSH9(half4(normal,1));
    half3 indirectDiffuse = ShadeSH9(half4(normal,1)) * occlusion;
    UnityIndirect indirect = {indirectDiffuse,indirectSpecular};
    return indirect;
}


/**
    emission color : rgb
    emission Mask : a
*/
half3 CalcEmission(half3 albedo,half2 uv){
    half4 tex = SAMPLE_TEXTURE2D(_EmissionMap,sampler_linear_repeat,uv);
    return albedo * tex.rgb * _EmissionColor.xyz * (tex.a * _Emission);
}

#define PBR_MODE_STANDARD 0
#define PBR_MODE_ANISO 1
#define PBR_MODE_CLOTH 2
#define PBR_MODE_STRAND 3

inline half3 CalcSpecularTermOnlyStandard(inout PBSData data,half nh,half3 specColor){
    return D_GGXTerm(nh,data.roughness2) * specColor;
}

inline half3 CalcDirectSpecColor(inout PBSData data,half nl,half nv,half nh,half lh,half3 specColor){
    half V = 1;
    half specTerm = 0;
    half3 directSpecColor = 0;

    #if defined(_PBRMODE_STANDRAD)
        specTerm = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2);
        // specTerm = D_GGXTerm(nh,data.roughness2);
        directSpecColor = specTerm * specColor;
    #endif

    #if defined(_PBRMODE_ANISO)
        half3 tangent = (data.tangent + data.normal * 0.1);
        half3 binormal = (data.binormal + data.normal * _AnisoShift);
        half th = dot(tangent,data.halfDir);
        half bh = dot(binormal,data.halfDir);
        // half tv = (dot(data.tangent,data.viewDir));
        // half tl = (dot(data.tangent,data.lightDir));
        // half bv = (dot(data.binormal,data.viewDir));
        // half bl = (dot(data.binormal,data.lightDir));

        half anisoRough = saturate(_AnisoRough) ;
        // specTerm = DV_SmithJointGGXAniso(th,bh,nh,tv,bv,nv,tl,bl,nl,anisoRough,1-anisoRough) ;
        // V = SmithJointGGXTerm(nl,nv,data.roughness);
        specTerm = D_GGXAniso(th,bh,nh,anisoRough,(1-anisoRough));
        // specTerm = D_WardAniso(nl,nv,nh,th,bh,anisoRough,1-anisoRough);
        directSpecColor = specTerm * _AnisoIntensity * _AnisoColor.xyz;
        
        if(_AnisoLayer2On){
            anisoRough = saturate(_Layer2AnisoRough);
            specTerm = D_GGXAniso(th,bh,nh,anisoRough,(1-anisoRough));
            // D = DV_SmithJointGGXAniso(th,bh,nh,tv,bv,nv,tl,bl,nl,anisoRough,1-anisoRough) ;
            directSpecColor += specTerm * _Layer2AnisoIntensity * _Layer2AnisoColor.xyz;
        }
        half anisoMask = GetMask(data.maskData_None_mainTexA_pbrMaskA,_AnisoMaskFrom);

        directSpecColor *= V * PI;
        directSpecColor *= lerp(1,anisoMask,_AnisoMaskUsage == ANISO_MASK_FOR_INTENSITY);
        directSpecColor *= lerp(1,1 - data.roughness,_AnisoIntensityUseSmoothness);
        directSpecColor *= specColor;

        if(_AnisoMaskUsage == ANISO_MASK_FOR_BLEND_STANDARD){
            half3 standardColor = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2) * specColor;
            directSpecColor = lerp(directSpecColor,standardColor,anisoMask);
        }
    #endif

    #if defined(_PBRMODE_CLOTH)
        // V = AshikhminV(nv,nl);
        specTerm = CharlieD(data.roughness,nh);
        specTerm = smoothstep(_ClothDMin,_ClothDMax,specTerm);
        directSpecColor = specTerm * PI * _ClothSheenColor;
        half clothMask = GetMask(data.maskData_None_mainTexA_pbrMaskA,_ClothMaskFrom);
        // mask control intensity
        directSpecColor *= lerp(1,clothMask,_ClothMaskUsage == CLOTH_MASK_FOR_INTENSITY);
        //mask control blend
        if(_ClothMaskUsage == CLOTH_MASK_FOR_BLEND_STANDARD){
            half3 standardColor = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2) * specColor;
            directSpecColor = lerp(directSpecColor,standardColor,clothMask);
        }
    #endif

    #if defined(_PBRMODE_STRANDSPEC)
        directSpecColor = data.hairSpecColor;
    #endif

    return min(directSpecColor * _SpecularIntensity, _MaxSpecularIntensity); // eliminate large value in HDR
}

half3 CalcIndirect(half smoothness,half roughness2,half oneMinusReflectivity,half3 giDiffColor,half3 giSpecColor,half3 diffColor,half3 specColor,half fresnelTerm){
    half3 indirectDiffuse = giDiffColor * diffColor;
    half surfaceReduction =1 /(roughness2 + 1); // [1,0.5]
    half grazingTerm = saturate(smoothness + 1 - oneMinusReflectivity); //smoothness + metallic

    half3 fresnelColor = _FresnelIntensity * grazingTerm * _FresnelColor;
    fresnelTerm = smoothstep(0,_FresnelWidth,fresnelTerm);

    half3 indirectSpecular = surfaceReduction * giSpecColor * lerp(specColor,fresnelColor,fresnelTerm);
    return indirectDiffuse + indirectSpecular;
}

half3 CalcIndirect(PBSData data,half3 giDiffColor,half3 giSpecColor,half3 diffColor,half3 specColor,half fresnelTerm){
    return CalcIndirect(data.smoothness,data.roughness2,data.oneMinusReflectivity,giDiffColor,giSpecColor,diffColor,specColor,fresnelTerm);
}

half3 CalcIndirectApplyClearCoat(half3 indirectColor,ClearCoatData data,half fresnelTerm){
    half3 coatSpecGI = GetIndirectSpecular(data.reflectDir,data.perceptualRoughness) * data.occlusion * _CoatIndirectSpecularIntensity;
    half3 coatColor = CalcIndirect(data.smoothness,data.roughness2,1-data.oneMinusReflectivity,0,coatSpecGI,0,data.specColor,fresnelTerm); // 1-data.oneMinusReflectivity approach unity_ColorSpaceDielectricSpec.x(0.04) 
    half coatFresnel = unity_ColorSpaceDielectricSpec.x + unity_ColorSpaceDielectricSpec.w * fresnelTerm;
    return indirectColor * (1 - coatFresnel) + coatColor;
}

half3 CalcDirect(inout PBSData data,half3 diffColor,half3 specColor,half nl,half nv,half nh,half lh){
    // half3 diffuseTerm = DisneyDiffuse(nl,nv,lh,data.roughness2) * diffColor;
    half3 directDiffuseColor = diffColor;
    half3 directSpecColor = 0;
    if(_SpecularOn){
        directSpecColor = CalcDirectSpecColor(data,nl,nv,nh,lh,specColor);
    }
    return directDiffuseColor + directSpecColor ;
}

half3 CalcDirectApplyClearCoat(half3 directColor,ClearCoatData data,half fresnelTerm,half nl,half nh,half lh){
    half3 specColor = 0;
    if(_SpecularOn){
        half3 coatSpec = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2) * data.specColor;
        half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * fresnelTerm;
        // return directColor * 1;
        specColor = directColor * (1-coatFresnel) + coatSpec;
    }
    return specColor;
}

#define CALC_LIGHT_INFO(lightDir)\
    half3 l = (lightDir);\
    half3 v = (data.viewDir);\
    half3 h = SafeNormalize(l + v);\
    half3 t = (data.tangent);\
    half3 b = (data.binormal);\
    half3 n = (data.normal);\
    half nh = saturate(dot(n,h));\
    half nl = saturate(dot(n,l));\
    half nv = saturate(dot(n,v));\
    half lh = saturate(dot(l,h));
    // half lv = saturate(dot(l,v));\

inline half3 CalcDirectAdditionalLight(PBSData data,half3 diffColor,half3 specColor,Light light){
    // CALC_LIGHT_INFO(light.direction);
    half3 h = SafeNormalize(light.direction + data.viewDir);
    half nl = saturate(dot(data.normal,light.direction));
    half nh = saturate(dot(data.normal,h));

    half lightAtten = light.distanceAttenuation * light.shadowAttenuation;
    // half3 directColor = CalcDirect(data/**/,diffColor,specColor,nl,nv,nh,lh,th,bh);
    half3 directColor = diffColor;
    if(_SpecularOn){
        directColor += CalcSpecularTermOnlyStandard(data,nh,specColor);
    }
    return lightAtten *nl * light.color * directColor;
}

half3 CalcPBSAdditionalLight(inout PBSData data,half3 diffColor,half3 specColor){
    half3 color = 0;
    // if(_ReceiveAdditionalLightsOn){
        int lightCount = GetAdditionalLightsCount();
        for(int lightId = 0 ; lightId <lightCount;lightId++){
            Light light1 = GetAdditionalLight(lightId,data.worldPos);
            
            color += CalcDirectAdditionalLight(data/**/,diffColor,specColor,light1);

            #if defined(_PRESSS)
            if(_ScatteringLUTOn && _AdditionalLightCalcScatter){
                half3 scatteredColor = PreScattering(data.normal,light1.direction,light1.color,data.nl,data.mainTex,data.worldPos,_CurvatureScale,_ScatteringIntensity,data.maskData_None_mainTexA_pbrMaskA);
                color.rgb += scatteredColor ;
            }
            #endif
            if(_SSSOn && _AdditionalLightCalcFastSSS){
                color.rgb += CalcSSS(light1.direction,data.viewDir,data.heightClothFastSSSMask.zw);
            }
        }
    // }
    return color;
}

half3 CalcIndirectApplySHDirLight(half3 indirectColor,PBSData data,half3 diffColor,half3 specColor){
    if (HasLightProbe() > 0)
    {
        Light light = GetDirLightFromUnityLightProbe();
        half3 lightColor = CalcDirectAdditionalLight(data, diffColor, specColor, light);
        indirectColor = indirectColor * rcp(1 + _AmbientSHIntensity)  + _DirectionalSHIntensity*lightColor; // orignal sh lighting as ambient
    }
    return indirectColor;
}

void ApplyThinFilm(half invertNV,half3 maskData,half baseMask,inout half3 specColor){
    #if defined(_THIN_FILM_ON)
        half tfMask = GetMaskForIntensity(maskData,_TFMaskFrom,_TFMaskUsage,THIN_FILE_MASK_FOR_INTENSITY) * baseMask;
        // half tfMask =  (_TFMaskUsage == THIN_FILE_MASK_FOR_INTENSITY) ? tfMaskData : 1;
        half3 thinFilm = ThinFilm(invertNV,_TFScale,_TFOffset,_TFSaturate,_TFBrightness);

        half3 tfSpecColor = (specColor + 1) * thinFilm ;
        specColor = lerp(specColor,tfSpecColor,tfMask);
    #endif
}

half4 CalcPBS(half3 diffColor,half3 specColor,UnityLight mainLight,UnityIndirect gi,ClearCoatData coatData,inout PBSData data){
    CALC_LIGHT_INFO(mainLight.dir);

    ApplyThinFilm(1-nv,data.maskData_None_mainTexA_pbrMaskA,_TFSpecMask ? nh : 1,specColor/**/);
    // set pbsdata for others flow.
    data.nl = nl;
    data.nv = nv;
    data.lightDir = l;
    data.halfDir = h;

    data.fresnelTerm = Pow4(1-nv);
    // indirect
    half3 color = CalcIndirect(data,gi.diffuse,gi.specular,diffColor,specColor,data.fresnelTerm );
    #if defined(_CLEARCOAT)
    // if(_ClearCoatOn){
        color = CalcIndirectApplyClearCoat(color,coatData,data.fresnelTerm );
    // }
    #endif

    // apply sh dir light
    #if defined(_DIRECTIONAL_LIGHT_FROM_SH)
    // if(_DirectionalLightFromSHOn){
        // color = CalcIndirectApplySHDirLight(color,data,diffColor,specColor);
    // }
    #endif

    // back face gi compensate.
    color += (1-nl) * _BackFaceGIDiffuse * diffColor;

    // direct
    half3 directColor = CalcDirect(data/**/,diffColor,specColor,nl,nv,nh,lh);

    #if defined(_CLEARCOAT)
    // if(_ClearCoatOn){
        directColor = CalcDirectApplyClearCoat(directColor,coatData/**/,data.fresnelTerm ,nl,nh,lh).xyzx;
    // }
    #endif
    // apply main light atten 
    directColor *= mainLight.color * nl;
    color += directColor;

    // additional lights
    #if defined(_ADDITIONAL_LIGHT)
    color += CalcPBSAdditionalLight(data/**/,diffColor,specColor);
    #endif

    return half4(color,1);
}

void ApplyVertexWave(inout half4 vertex,half3 normal,half4 vertexColor){
    vertex.xyz += _VertexScale * vertexColor.x * normal;
}

half3 CalcDiffuseAndSpecularFromMetallic(half3 albedo,half metallic,inout half3 specColor,out half oneMinusReflectivity){
    specColor = lerp(unity_ColorSpaceDielectricSpec.rgb,albedo,metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}

half ReflectivitySpecular(half3 specColor){
    return max(max(specColor.x,specColor.y),specColor.z);
}

void InitSurfaceData(half2 uv,half3 albedo,half alpha,half metallic,out SurfaceData data){
    // --- specular map flow
    // if(_CustomSpecularMapOn){
    #if defined(_SPECULAR_MAP_FLOW)
        half2 specUV = TRANSFORM_TEX(uv,_CustomSpecularMap);
        half4 customSpecColor = SAMPLE_TEXTURE2D(_CustomSpecularMap,sampler_linear_repeat,specUV);
        data.specColor = lerp(unity_ColorSpaceDielectricSpec.xyz,customSpecColor.xyz,_Metallic) * customSpecColor.w * _CustomSpecularIntensity;
        data.oneMinusReflectivity = 1.0 - ReflectivitySpecular(data.specColor);
        data.diffColor = albedo * (1 - data.specColor);
    // }else{
    #else 
        // metallic flow
        data.diffColor = DiffuseAndSpecularFromMetallic (albedo, metallic, /*inout*/ data.specColor, /*out*/ data.oneMinusReflectivity);
    // }
    #endif
    
    data.diffColor = AlphaPreMultiply (data.diffColor, alpha, data.oneMinusReflectivity, /*out*/ data.finalAlpha);
}

void InitWorldData(half2 uv,half detailMask,half4 tSpace0,half4 tSpace1,half4 tSpace2,out WorldData data ){
    half2 normalMapUV = TRANSFORM_TEX(uv, _NormalMap);
    half3 tn = CalcNormal(normalMapUV,detailMask);
    data.normal = SafeNormalize(half3(
        dot(tSpace0.xyz,tn),
        dot(tSpace1.xyz,tn),
        dot(tSpace2.xyz,tn)
    ));

    data.pos = half3(tSpace0.w,tSpace1.w,tSpace2.w);
    data.view = normalize(GetWorldViewDir(data.pos));
    data.reflect = (reflect(-data.view + _ReflectionOffsetDir.xyz,data.normal));

    data.vertexNormal = (half3(tSpace0.z,tSpace1.z,tSpace2.z));
    data.vertexTangent = (half3(tSpace0.x,tSpace1.x,tSpace2.x));
    data.vertexBinormal = (half3(tSpace0.y,tSpace1.y,tSpace2.y));


    half3 t = cross(data.normal,data.vertexBinormal); // schmidt orthogonal
    data.tangent = normalize(t - dot(t,data.normal) * data.normal);
    data.binormal =(cross(data.tangent,data.normal));

    // data.binormal = data.vertexBinormal;
    // data.tangent = data.vertexTangent;
    // data.normal = data.vertexNormal;
}

#endif // end of POWER_PBS_CORE_HLSL