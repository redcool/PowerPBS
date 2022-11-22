#if !defined (POWER_PBS_CORE_HLSL)
#define POWER_PBS_CORE_HLSL
#include "PowerPBSData.hlsl"

#include "../../PowerShaderLib/UrpLib/URP_GI.hlsl"
#include "../../PowerShaderLib/UrpLib/URP_Lighting.hlsl"
#include "Tools/ExtractLightFromSH.hlsl"
#include "../../PowerShaderLib/Lib/BSDF.hlsl"
#include "../../PowerShaderLib/Lib/Colors.hlsl"
#include "../../PowerShaderLib/Lib/MaskLib.hlsl"
#include "../../PowerShaderLib/Lib/ToneMappers.hlsl"
#include "../../PowerShaderLib/Lib/PowerUtils.hlsl"

void OffsetMainLight(inout Light light){
    light.direction += _CustomLightOn > 0 ? _LightDir.xyz : 0;
    light.color += _CustomLightOn > 0 ?_LightColor.xyz : 0;
    light.direction = normalize(light.direction);
}

float3 CalcSSS(float3 l,float3 v,float2 fastSSSMask){
    float sss1 = FastSSS(l,v);
    float sss2 = FastSSS(-l,v);
    float3 front = sss1 * _FrontSSSIntensity * fastSSSMask.x * _FrontSSSColor;
    float3 back = sss2 * _BackSSSIntensity * fastSSSMask.y * _BackSSSColor;
    return (front + back);
}

float3 GetWorldViewDir(float3 worldPos){
    float3 dir = 0;
    if(unity_OrthoParams.w != 0){ // ortho
        // dir = float3(UNITY_MATRIX_MV[0].z,UNITY_MATRIX_MV[1].z,UNITY_MATRIX_MV[2].z);
        dir = UNITY_MATRIX_V[2].xyz;
    }else
        dir = UnityWorldSpaceViewDir(worldPos);
    return dir;
}

float3 PreScattering(float3 normal,float3 lightDir,float3 lightColor,float nl,float4 mainTex,float3 worldPos,float curveScale,float scatterIntensity,float3 maskData){
    float wnl = dot(normal,(lightDir)) * 0.5 + 0.5;
    // float deltaNormal = length(fwidth(normal))*10;
    // float deltaPos = length(fwidth(worldPos));
    // float curvature = deltaNormal/1 * curveScale;
    float atten = 1-wnl;//smoothstep(0.,0.5,nl);
    float4 scattering = SAMPLE_TEXTURE2D(_ScatteringLUT,sampler_linear_repeat,float2(wnl,curveScale ));

    float mask = GetMaskForIntensity(maskData,_PreScatterMaskFrom,_PreScatterMaskUsage,PRESSS_MASK_FOR_INTENSITY);

    return scattering.xyz * lightColor * mainTex.xyz * atten * scatterIntensity * mask;
}

float3 GetIndirectSpecular(float3 reflectDir,float rough){
    float mip = (1.7-0.7*rough)*rough*6;

    float4 encodeIrradiance = 0;
    if(_CustomIBLOn){
        encodeIrradiance = SAMPLE_TEXTURECUBE_LOD(_EnvCube,sampler_linear_repeat,reflectDir,mip);
    }else{
        encodeIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,sampler_linear_repeat, reflectDir, mip);
    }
    encodeIrradiance *= _EnvIntensity;
    return DecodeHDR(encodeIrradiance,unity_SpecCube0_HDR);
}


float3 AlphaPreMultiply (float3 diffColor, float alpha, float oneMinusReflectivity, out float outModifiedAlpha)
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

float3 CalcNormal(float2 uv, float detailMask ){
    float3 tn = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv),_NormalMapScale);
	
	// if (_Detail_MapOn) {
    #if defined(_DETAIL_MAP)
        float2 dnUV = uv * _Detail_NormalMap_ST.xy + _Detail_NormalMap_ST.zw;
		float3 dn = UnpackNormalScale(SAMPLE_TEXTURE2D(_Detail_NormalMap,sampler_linear_repeat, dnUV), _Detail_NormalMapScale);
		// dn = normalize(float3(tn.xy + dn.xy, tn.z*dn.z));
		tn = lerp(tn, dn, detailMask);
	// }
    #endif
    return tn;
}

float CalcDetailAlbedo(inout float4 mainColor, TEXTURE2D(texObj),float2 uv, float detailIntensity,bool isOn,int detailMapMode){
    float detailMask = 0;
    if(isOn){
        float4 tex = SAMPLE_TEXTURE2D(texObj,sampler_linear_repeat,uv);
		float3 detailAlbedo = tex.xyz;
        detailMask = tex.w;
        float mask = detailMask * detailIntensity;
        if(detailMapMode == DETAIL_MAP_MODE_MULTIPLY){
            mainColor.rgb *= lerp(1,detailAlbedo * unity_ColorSpaceDouble.xyz,mask); //unity_ColorSpaceDouble linear pow(2,2.2)
        }else if(detailMapMode == DETAIL_MAP_MODE_REPLACE){
            mainColor.rgb = lerp(mainColor.xyz,detailAlbedo,mask);
        }
    }
    return detailMask;
}

#define CALC_DETAIL_ALBEDO(id) CalcDetailAlbedo(albedo, _Detail##id##_Map,TRANSFORM_TEX(uv,_Detail##id##_Map), _Detail##id##_MapIntensity, _Detail##id##_MapOn,_Detail##id##_MapMode)

float4 CalcAlbedo(float2 uv,out float detailMask) 
{
    detailMask = 1;
    float4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv) ;
    #if defined(_DETAIL_MAP)
        detailMask = CALC_DETAIL_ALBEDO();
        CALC_DETAIL_ALBEDO(1);
        // CALC_DETAIL_ALBEDO(2);
        // CALC_DETAIL_ALBEDO(3);
        // CALC_DETAIL_ALBEDO(4);
    #endif
    return albedo;
}

UnityIndirect CalcGI(float3 albedo,float2 uv,float3 reflectDir,float3 normal,float3 occlusion,float roughness){
    float3 indirectSpecular = GetIndirectSpecular(reflectDir,roughness) * occlusion * _IndirectSpecularIntensity;
    // float3 indirectDiffuse = albedo * occlusion;
    float3 indirectDiffuse = SampleSH(normal) * occlusion;
    UnityIndirect indirect = {indirectDiffuse,indirectSpecular};
    return indirect;
}


/**
    emission color : rgb
    emission Mask : a
*/
float3 CalcEmission(float3 albedo,float2 uv){
    float4 tex = SAMPLE_TEXTURE2D(_EmissionMap,sampler_linear_repeat,uv);
    return albedo * tex.rgb * _EmissionColor.xyz * (tex.a * _Emission);
}

void InitWorldData(float2 uv,float detailMask,float4 tSpace0,float4 tSpace1,float4 tSpace2,out WorldData data ){
    data.pos = float3(tSpace0.w,tSpace1.w,tSpace2.w);

    // tangent normal
    float2 normalMapUV = TRANSFORM_TEX(uv, _NormalMap);
    float3 tn = CalcNormal(normalMapUV,detailMask);

    // blend vertex normal in tangent space
    #if defined(_BLEND_VERTEX_NORMAL_ON)

        tn = BlendVertexNormal(tn,data.pos,
        float3(tSpace0.x,tSpace1.x,tSpace2.x),
        float3(tSpace0.y,tSpace1.y,tSpace2.y),
        float3(tSpace0.z,tSpace1.z,tSpace2.z)
        );
    #endif

    // transform tangent to world space
    data.normal = SafeNormalize(float3(
        dot(tSpace0.xyz,tn),
        dot(tSpace1.xyz,tn),
        dot(tSpace2.xyz,tn)
    ));

    data.view = normalize(GetWorldViewDir(data.pos));
    data.reflect = (reflect(-data.view + _ReflectionOffsetDir.xyz,data.normal));

    data.vertexNormal = (float3(tSpace0.z,tSpace1.z,tSpace2.z));
    data.vertexTangent = (float3(tSpace0.x,tSpace1.x,tSpace2.x));
    data.vertexBinormal = (float3(tSpace0.y,tSpace1.y,tSpace2.y));


    float3 t = cross(data.normal,data.vertexBinormal);
    data.tangent = normalize(t - dot(t,data.normal) * data.normal); // schmidt orthogonal
    data.binormal =(cross(data.tangent,data.normal));

    // data.binormal = data.vertexBinormal;
    // data.tangent = data.vertexTangent;
    // data.normal = data.vertexNormal;
}




#define PBR_MODE_STANDARD 0
#define PBR_MODE_ANISO 1
#define PBR_MODE_CLOTH 2
#define PBR_MODE_STRAND 3

float3 CalcSpecularTermOnlyStandard(inout PBSData data,float nh,float3 specColor){
    return D_GGXTerm(nh,data.roughness2) * specColor;
}

float3 CalcDirectSpecColor(inout PBSData data,float nl,float nv,float nh,float lh,float3 specColor){
    float V = 1;
    float specTerm = 0;
    float3 directSpecColor = 0;

    #if defined(_PBRMODE_STANDRAD)
        specTerm = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2);
        // specTerm = D_GGXTerm(nh,data.roughness2);
        directSpecColor = specTerm * specColor;
    #endif

    #if defined(_PBRMODE_ANISO)
        float3 tangent = (data.tangent + data.normal * 0.1);
        float3 binormal = (data.binormal + data.normal * _AnisoShift);
        float th = dot(tangent,data.floatDir);
        float bh = dot(binormal,data.floatDir);
        // float tv = (dot(data.tangent,data.viewDir));
        // float tl = (dot(data.tangent,data.lightDir));
        // float bv = (dot(data.binormal,data.viewDir));
        // float bl = (dot(data.binormal,data.lightDir));

        float anisoRough = saturate(_AnisoRough) ;
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
        float anisoMask = GetMask(data.maskData_None_mainTexA_pbrMaskA,_AnisoMaskFrom);

        directSpecColor *= V * PI;
        directSpecColor *= lerp(1,anisoMask,_AnisoMaskUsage == ANISO_MASK_FOR_INTENSITY);
        directSpecColor *= lerp(1,1 - data.roughness,_AnisoIntensityUseSmoothness);
        directSpecColor *= specColor;

        if(_AnisoMaskUsage == ANISO_MASK_FOR_BLEND_STANDARD){
            float3 standardColor = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2) * specColor;
            directSpecColor = lerp(directSpecColor,standardColor,anisoMask);
        }
    #endif

    #if defined(_PBRMODE_CLOTH)
        // V = AshikhminV(nv,nl);
        specTerm = CharlieD(data.roughness,nh);
        specTerm = smoothstep(_ClothSheenRange.x,_ClothSheenRange.y,specTerm);
        directSpecColor = specTerm * PI * _ClothSheenColor.xyz;
        float clothMask = GetMask(data.maskData_None_mainTexA_pbrMaskA,_ClothMaskFrom);
        // mask control intensity
        directSpecColor *= lerp(1,clothMask,_ClothMaskUsage == CLOTH_MASK_FOR_INTENSITY);
        //mask control blend
        if(_ClothMaskUsage == CLOTH_MASK_FOR_BLEND_STANDARD){
            float3 standardColor = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2) * specColor;
            directSpecColor = lerp(directSpecColor,standardColor,clothMask);
        }
    #endif

    return min(directSpecColor * _SpecularIntensity, _MaxSpecularIntensity); // eliminate large value in HDR
}

float3 CalcIndirect(float smoothness,float roughness2,float oneMinusReflectivity,float3 giDiffColor,float3 giSpecColor,float3 diffColor,float3 specColor,float fresnelTerm){
    float3 indirectDiffuse = giDiffColor * diffColor;
    float surfaceReduction =1 /(roughness2 + 1); // [1,0.5]
    float grazingTerm = saturate(smoothness + 1 - oneMinusReflectivity); //smoothness + metallic

    float3 fresnelColor = _FresnelIntensity * grazingTerm * _FresnelColor;
    fresnelTerm = smoothstep(0,_FresnelWidth,fresnelTerm);

    float3 indirectSpecular = surfaceReduction * giSpecColor * lerp(specColor,fresnelColor,fresnelTerm);
    return indirectDiffuse + indirectSpecular;
}

float3 CalcIndirect(PBSData data,float3 giDiffColor,float3 giSpecColor,float3 diffColor,float3 specColor,float fresnelTerm){
    return CalcIndirect(data.smoothness,data.roughness2,data.oneMinusReflectivity,giDiffColor,giSpecColor,diffColor,specColor,fresnelTerm);
}

float3 CalcIndirectApplyClearCoat(float3 indirectColor,ClearCoatData data,float fresnelTerm){
    float3 coatSpecGI = GetIndirectSpecular(data.reflectDir,data.perceptualRoughness) * data.occlusion * _CoatIndirectSpecularIntensity;
    float3 coatColor = CalcIndirect(data.smoothness,data.roughness2,1-data.oneMinusReflectivity,0,coatSpecGI,0,data.specColor,fresnelTerm); // 1-data.oneMinusReflectivity approach unity_ColorSpaceDielectricSpec.x(0.04) 
    // float coatFresnel = 0.04 + 0.96 * fresnelTerm;
    return indirectColor * (1 - fresnelTerm) + coatColor;
}

float3 CalcDirect(inout PBSData data,float3 diffColor,float3 specColor,float nl,float nv,float nh,float lh){
    // float3 diffuseTerm = DisneyDiffuse(nl,nv,lh,data.roughness2) * diffColor;
    float3 directDiffuseColor = diffColor;
    float3 directSpecColor = 0;
    // if(!_SpecularOff)
    #if !defined(_SPECULAR_OFF)
    {
        directSpecColor = CalcDirectSpecColor(data,nl,nv,nh,lh,specColor);
    }
    #endif
    return directDiffuseColor + directSpecColor ;
}

float3 CalcDirectApplyClearCoat(float3 directColor,ClearCoatData data,float fresnelTerm,float nl,float nh,float lh){
    float3 specColor = 0;
    // if(!_SpecularOff)
    #if !defined(_SPECULAR_OFF)
    {
        float3 coatSpec = MinimalistCookTorrance(nh,lh,data.roughness,data.roughness2) * data.specColor;
        float coatFresnel = kDielectricSpec.x + kDielectricSpec.a * fresnelTerm;
        // return directColor * 1;
        specColor = directColor * (1-coatFresnel) + coatSpec;
    }
    #endif
    return specColor;
}

#define CALC_LIGHT_INFO(lightDir)\
    float3 l = (lightDir);\
    float3 v = (data.viewDir);\
    float3 h = SafeNormalize(l + v);\
    float3 t = (data.tangent);\
    float3 b = (data.binormal);\
    float3 n = (data.normal);\
    float nh = (dot(n,h));\
    float nl = (dot(n,l));\
    float nv = (dot(n,v));\
    float lh = saturate(dot(l,h));\
    float wnv = nv*0.5+0.5;\
    nh = saturate(nh); nl = saturate(nl); nv = saturate(nv);
    // float lv = saturate(dot(l,v));\

float3 CalcDirectAdditionalLight(PBSData data,float3 diffColor,float3 specColor,Light light){
    // CALC_LIGHT_INFO(light.direction);
    float3 h = SafeNormalize(light.direction + data.viewDir);
    float nl = saturate(dot(data.normal,light.direction));
    float nh = saturate(dot(data.normal,h));

    float lightAtten = light.distanceAttenuation * light.shadowAttenuation *nl ;
    // float3 directColor = CalcDirect(data/**/,diffColor,specColor,nl,nv,nh,lh,th,bh);
    float3 directColor = diffColor;
    // if(!_SpecularOff)
    #if !defined(_SPECULAR_OFF)
    {
        directColor += CalcSpecularTermOnlyStandard(data,nh,specColor);
    }
    #endif
    return lerp(_ShadowColor.xyz,1,lightAtten) * light.color * directColor;
}

float3 CalcPBSAdditionalLight(inout PBSData data,float3 diffColor,float3 specColor){
    float3 color = 0;
    // float atten = 0;

    int lightCount = GetAdditionalLightsCount();
    for(int lightId = 0 ; lightId <lightCount;lightId++){
        Light light1 = GetAdditionalLight(lightId,data.worldPos);
        // atten += light1.shadowAttenuation;
        
        if(light1.distanceAttenuation)
            color += CalcDirectAdditionalLight(data/**/,diffColor,specColor,light1);

        #if defined(_PRESSS)
        if(_AdditionalLightCalcScatter){
            float3 scatteredColor = PreScattering(data.normal,light1.direction,light1.color,data.nl,data.mainTex,data.worldPos,_CurvatureScale,_ScatteringIntensity,data.maskData_None_mainTexA_pbrMaskA);
            color.rgb += scatteredColor ;
        }
        #endif
        
        #if defined(_FAST_SSS)
        if(_AdditionalLightCalcFastSSS){
            color.rgb += CalcSSS(light1.direction,data.viewDir,data.heightClothFastSSSMask.zw);
        }
        #endif
    }
    return color;
}

float3 CalcIndirectApplySHDirLight(float3 indirectColor,PBSData data,float3 diffColor,float3 specColor){
    if (HasLightProbe() > 0)
    {
        Light light = GetDirLightFromUnityLightProbe();
        float3 lightColor = CalcDirectAdditionalLight(data, diffColor, specColor, light);
        indirectColor = indirectColor * rcp(1 + _AmbientSHIntensity)  + _DirectionalSHIntensity*lightColor; // orignal sh lighting as ambient
    }
    return indirectColor;
}

void ApplyThinFilm(float invertNV,float3 maskData,float baseMask,inout float3 specColor){
    float tfMask = GetMaskForIntensity(maskData,_TFMaskFrom,_TFMaskUsage,THIN_FILE_MASK_FOR_INTENSITY) * baseMask;
    // float tfMask =  (_TFMaskUsage == THIN_FILE_MASK_FOR_INTENSITY) ? tfMaskData : 1;
    float3 thinFilm = ThinFilm(invertNV,_TFScale,_TFOffset,_TFSaturate,_TFBrightness);

    float3 tfSpecColor = (specColor + 1) * thinFilm ;
    specColor = lerp(specColor,tfSpecColor,tfMask);
}

float4 CalcPBS(float3 diffColor,float3 specColor,Light mainLight,UnityIndirect gi,ClearCoatData coatData,inout PBSData data){
    CALC_LIGHT_INFO(mainLight.direction);

    // shell layer 
    #if defined(_SHEEN_LAYER_ON)
    diffColor *= SheenLayer(nh,wnv,_SheenLayerRange.xy,_SheenLayerRange.z,_SheenLayerRange.w);
    // diffColor = diffColor/(1+diffColor);
    // diffColor = GTTone(diffColor);
    if(_SheenLayerApplyTone){
        // diffColor += lerp(0,float3(.1,0,0),1-wnv);
        diffColor = ACESFilm(diffColor);
    }
    #endif

    #if defined(_THIN_FILM_ON)
    ApplyThinFilm(1-nv,data.maskData_None_mainTexA_pbrMaskA,_TFSpecMask ? nh : 1,specColor/**/);
    #endif

    // set pbsdata for others flow.
    data.nl = nl;
    data.nv = nv;
    data.lightDir = l;
    data.floatDir = h;

    data.fresnelTerm = Pow4(1-nv);
    // indirect
    float3 color = CalcIndirect(data,gi.diffuse,gi.specular,diffColor,specColor,data.fresnelTerm );
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
    float3 directColor = 0;
    
    if(mainLight.distanceAttenuation)
        directColor = CalcDirect(data/**/,diffColor,specColor,nl,nv,nh,lh);

    #if defined(_CLEARCOAT)
    // if(_ClearCoatOn){
        directColor = CalcDirectApplyClearCoat(directColor,coatData/**/,data.fresnelTerm ,nl,nh,lh).xyzx;
    // }
    #endif
    // apply main light atten 
    float atten = (nl * mainLight.shadowAttenuation * mainLight.distanceAttenuation);
    directColor *= mainLight.color * lerp(_ShadowColor.xyz,1,atten);
    color += directColor;

    // additional lights
    #if defined(_ADDITIONAL_LIGHTS)
        color += CalcPBSAdditionalLight(data/**/,diffColor,specColor);
    #endif

    return float4(color,1);
}

void ApplyVertexWave(inout float4 vertex,float3 normal,float4 vertexColor){
    vertex.xyz += _VertexScale * lerp(1,vertexColor.x,_VertexColorRAttenOn) * normal;
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
    // if(_CustomSpecularMapOn){
    #if defined(_SPECULAR_MAP_FLOW)
        float2 specUV = TRANSFORM_TEX(uv,_CustomSpecularMap);
        float4 customSpecColor = SAMPLE_TEXTURE2D(_CustomSpecularMap,sampler_linear_repeat,specUV);
        data.specColor = lerp(unity_ColorSpaceDielectricSpec.xyz,customSpecColor.xyz,_SpecMapScale * customSpecColor.w) * _CustomSpecularIntensity;
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



#endif // end of POWER_PBS_CORE_HLSL