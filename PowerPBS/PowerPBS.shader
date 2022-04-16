/**
    pbs渲染流程
    1 URP asset add PowerUrpLitFeature

    usecase :
    drp 
        uncomment 
            Tags{"LightMode"="ForwardBase" }
        comment
            #define URP_SHADOW
    urp
        comment
            Tags{"LightMode"="ForwardBase" }
        comment
            #define URP_SHADOW
*/
Shader "Character/PowerPBS"
{
    Properties
    {
        // [Header(Drp BakedLight LightingProcess Is Required)]
// ==================================================
        [Header(MainProp)]
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color("Color",color) = (1,1,1,1)

        [Space(5)]
        [Enum(MainTex,0,PbrMask,1)]_AlphaFrom("_AlphaFrom(MainTex,PbrMask)",int) = 0

        [Space(5)]
        _NormalMap("NormalMap",2d) = "bump"{}
        _NormalMapScale("_NormalMapScale",range(0,5)) = 1

        [Header(PBR Mask)]
        [noscaleoffset]_MetallicMap("Metallic(R),Smoothness(G),Occlusion(B)",2d) = "white"{}

        [Header(PBR Slider)]
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("Smoothness",range(0,1)) = 0
        _Occlusion("_Occlusion",range(0,1)) = 1
        
        [Header(PBR Slider Options)]
        [GroupToggle]_InvertSmoothnessOn("_InvertSmoothnessOn",int) = 0

        [Header(PBR Mask Channel)]
        [Enum(R,0,G,1,B,2,A,3)]_MetallicChannel("_MetallicChannel",float) = 0
        [Enum(R,0,G,1,B,2,A,3)]_SmoothnessChannel("_SmoothnessChannel",float) = 1
        [Enum(R,0,G,1,B,2,A,3)]_OcclusionChannel("_OcclusionChannel",float) = 2

        [Header(Custom Specular)]
        [Toggle(_SPECULAR_MAP_FLOW)]_CustomSpecularMapOn("_CustomSpecularMapOn",int) = 0
        _CustomSpecularMap("_CustomSpecularMap(a:Mask(0:DielectricSpec,1:CustomSpecColor))",2d) ="white"{}
        _CustomSpecularIntensity("_CustomSpecularIntensity",float) = 1
        
        [Header(Clear Coat)]
        [Toggle(_CLEARCOAT)]_ClearCoatOn("_ClearCoatOn",int) = 0
        _ClearCoatSpecColor("_ClearCoatSpecColor",color) = (1,1,1,1)
        _CoatSmoothness("_CoatSmoothness",range(0,1)) = 0.5
        _CoatIndirectSpecularIntensity("_CoatIndirectSpecularIntensity",float) = 1

// ================================================== vertex
        [Header(Vertex Scale)]
        _VertexScale("_VertexScale",range(-0.1,0.1)) = 0
        [GroupToggle]_VertexColorRAttenOn("_VertexColorRAttenOn(R)",int) = 1
// ================================================== Settings
        [Header(PBR Mode)]
        // [Enum(Standard,0,Aniso,1,Cloth,2,StrandSpec,3)]_PBRMode("_PBRMode",int) = 0
        [KeywordEnum(Standard,Aniso,Cloth,StrandSpec)]_PBRMode("_PBRMode",int) = 0

        [Header(Specular Options)]
        [GroupToggle]_SpecularOn("_SpecularOn",float) = 1
        _MaxSpecularIntensity("_MaxSpecularIntensity", range(0, 10)) = 5
        _SpecularColorScale("_SpecularColorScale",range(1,5)) = 1
        _SpecularIntensity("_SpecularIntensity",range(1,5)) = 1

        [Header(Fresnel Options)]
        _FresnelIntensity("_FresnelIntensity",range(0,3)) = 1
        _FresnelColor("_FresnelColor",Color) = (1,1,1,1)
        _FresnelWidth("_FresnelWidth",range(0.01,1)) = 1
// ==================================================
        [Space(10)][Header(Shadow)]
        [GroupToggle]_ApplyShadowOn("_ApplyShadowOn",int) = 1
        _MainLightShadowSoftScale("_MainLightShadowSoftScale",range(0.01,3)) = 1
        [Header(Shadow Bias)]
        _CustomShadowBias("_CustomShadowBias(x: depth bias, y: normal bias)",vector) = (0,0,0,0)

        [Header(URP Additional Lights)]
        [Toggle(_ADDITIONAL_LIGHT)]_ReceiveAdditionalLightsOn("_ReceiveAdditionalLightsOn",int) = 1
        [GroupToggle]_ReceiveAdditionalLightsShadowOn("_ReceiveAdditionalLightsShadowOn",int) = 1
        [GroupToggle]_AdditionalLightSoftShadowOn("_AdditionalLightSoftShadowOn",int) = 0

        [Header(Spherical Harmonics)]
        [Toggle(_DIRECTIONAL_LIGHT_FROM_SH)]_DirectionalLightFromSHOn("_DirectionalLightFromSHOn",int) = 0
        _AmbientSHIntensity("_AmbientSHIntensity",range(0,1)) = 0.5
        _DirectionalSHIntensity("_DirectionalSHIntensity", range(0, 1)) = 0.5
// ==================================================
        [Header(Anisotropic)]
        _AnisoColor("_AnisoColor",color) = (1,1,0,1)
        _AnisoIntensity("_AnisoIntensity",range(0,10)) = 1
        _AnisoRough("_AnisoRough",range(0,1)) = 0
        _AnisoShift("_AnisoShift",float) = 0
        // ---- layer2
        [Header(Aniso2)]
        [GroupToggle]_AnisoLayer2On("_AnisoLayer2On",int) = 0
        _Layer2AnisoColor("_Layer2AnisoColor",color) = (.5,0,0,0)
        _Layer2AnisoIntensity("_Layer2AnisoIntensity",range(0,10)) = 1
        _Layer2AnisoRough("_Layer2AnisoRough",range(0,1)) = 0
        // _Layer2AnisoShift("_Layer2AnisoShift",float) = 0
        [Header(Mask)]
        [Enum(None,0,MainTexA,1,PbrMaskA,2)]_AnisoMaskFrom("_AnisoMaskFrom",float) = 0
        [Enum(None,0,Intensity,1,BlendStardard,2)]_AnisoMaskUsage("_AnisoMaskUsage",float)=0
        [GroupToggle]_AnisoIntensityUseSmoothness("_AnisoIntensityUseSmoothness",float) = 0
// ==================================================
        [Header(Pre Integral Scatter)]
        [Toggle(_PRESSS)]_ScatteringLUTOn("_ScatteringLUTOn",float) = 0
        [NoScaleOffset]_ScatteringLUT("_ScatteringLUT",2d) = ""{}
        _ScatteringIntensity("_ScatteringIntensity",range(0,3)) = 1
        _CurvatureScale("_CurvatureScale (MainTex.a)",range(0.01,0.99)) = 1

        [Header(Mask)]
        [Enum(None,0,MainTexA,1,PbrMaskA,2)]_PreScatterMaskFrom("_AnisoMaskFrom",float) = 0
        [Enum(None,0,Intensity,1)]_PreScatterMaskUsage("_AnisoMaskUsage",float)=0

        [Header(Light Ops)]
        [GroupToggle]_LightColorNoAtten("_LightColorNoAtten",int) = 1
        [GroupToggle]_AdditionalLightCalcScatter("_AdditionalLightCalcScatter",int) = 0

        [Header(Diffuse Profile ScreenSpace)]
        [Toggle(_SSSS)]_DiffuseProfileOn("_DiffuseProfileOn",int) = 0
        _BlurSize("_BlurSize",range(0,20)) = 1

        [Header(SSSS Mask)]
        [Enum(None,0,MainTexA,1,PbrMaskA,2)]_SSSSMaskFrom("_SSSSMaskFrom",float) = 0
        [Enum(None,0,Intensity,1)]_SSSSMaskUsage("_SSSSMaskUsage",float)=0
// ==================================================
        [Header(Cloth Spec)]
        [hdr]_ClothSheenColor("_ClothSheenColor",Color) = (1,1,1,1)
        _ClothDMin("_ClothDMin",range(0,1)) = 0
        _ClothDMax("_ClothDMax",range(0,1)) = 1
        
        [Header(Mask)]
        [Enum(None,0,MainTexA,1,PbrMaskA,2)]_ClothMaskFrom("_ClothMaskFrom",int) = 0
        [Enum(None,0,Intensity,1,BlendStandard,2)]_ClothMaskUsage("_ClothMaskUsage",int) = 0
// ==================================================
        // [GroupToggle]_Detail4_MapOn("_Detail4_MapOn",int) = 0
        // [Enum(Multiply,0,Replace,1)]_Detail4_MapMode("_Detail4_MapMode",int) = 0
        // _Detail4_Map("_Detail4_Map(RGB),Detail4_Mask(A)",2d) = "white"{}
        // _Detail4_MapIntensity("_Detail4_MapIntensity",range(0,1)) = 1

        // [Space(10)][Header(Detail3_Map)]
        // [GroupToggle]_Detail3_MapOn("_Detail3_MapOn",int) = 0
        // [Enum(Multiply,0,Replace,1)]_Detail3_MapMode("_Detail3_MapMode",int) = 0
        // _Detail3_Map("_Detail3_Map(RGB),Detail3_Mask(A)",2d) = "white"{}
        // _Detail3_MapIntensity("_Detail3_MapIntensity",range(0,1)) = 1

        // [Space(10)][Header(Detail2_Map)]
        // [GroupToggle]_Detail2_MapOn("_Detail2_MapOn",int) = 0
        // [Enum(Multiply,0,Replace,1)]_Detail2_MapMode("_Detail2_MapMode",int) = 0
        // _Detail2_Map("_Detail2_Map(RGB),EyeMask(A)",2d) = "white"{}
        // _Detail2_MapIntensity("_Detail2_MapIntensity",range(0,1)) = 1

        [Space(10)][Header(Detail1_Map)]
        [GroupToggle]_Detail1_MapOn("_Detail1_MapOn",int) = 0
        [Enum(Multiply,0,Replace,1)]_Detail1_MapMode("_Detail1_MapMode",int) = 0
        _Detail1_Map("_Detail1_Map(rgb),Mask(A)",2d) = "white"{}
        _Detail1_MapIntensity("_Detail1_MapIntensity",range(0,1)) = 1

        [Space(10)][Header(DetailMap)]
        [Toggle(_DETAIL_MAP)]_Detail_MapOn("_Detail_MapOn",int) = 0
        [Enum(Multiply,0,Replace,1)]_Detail_MapMode("_Detail_MapMode",int) = 0
        _Detail_Map("_Detail_Map(RGB),DetailMask(A)",2d) = "white"{}
        _Detail_MapIntensity("_Detail_MapIntensity",range(0,1)) = 1
        _Detail_NormalMap("_Detail_NormalMap",2d) = "bump"{}
        _Detail_NormalMapScale("_Detail_NormalMapScale",range(0,5)) = 1
 // ==================================================       
        [Space(10)][Header(Custom IBL)]
        [GroupToggle]_CustomIBLOn("_CustomIBLOn",float) = 0
        [noscaleoffset]_EnvCube("_EnvCube",cube) = "white"{}
        _EnvIntensity("_EnvIntensity",float) = 1
        _ReflectionOffsetDir("_ReflectionOffsetDir",vector) = (0,0,0,0)
// ==================================================
        [Space(10)][Header(Emission)]
        [GroupToggle]_EmissionOn("_EmissionOn",float) = 0
        [noscaleoffset]_EmissionMap("_EmissionMap(RGB),EmissionMask(A)",2d) = "white"{}
        [hdr]_EmissionColor("_EmissionColor",color) = (1,1,1,1)
        _Emission("_Emission",float) = 1
// ==================================================
        [Space(10)][Header(GI )]
        _IndirectSpecularIntensity("_IndirectSpecularIntensity",float) = 1
        _BackFaceGIDiffuse("_BackFaceGIDiffuse",range(0,1)) = 0
// ==================================================
        [Space(10)][Header(CustomLight)]
        [GroupToggle]_CustomLightOn("_CustomLightOn",int) = 0
        _LightDir("_LightDir",vector) = (0,0.5,0,0)
        _LightColor("_LightColor",color) = (1,1,1,1)
// ==================================================
        [Space(10)][Header(AlphaTest)]
        [Toggle(_ALPHA_TEST)]_AlphaTestOn("_AlphaTestOn",int) = 0
        _Cutoff("_Cutoff",range(0,1)) = 0.5

        [Space(10)][Header(AlphaBlendMode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0

        [Space(10)][Header(AlphaMultiMode)]
        [GroupToggle]_AlphaPreMultiply("_AlphaPreMultiply",int) = 0

        [Header(Fresnel affect)]
        [GroupToggle]_FresnelAlphaOn("_FresnelAlphaOn",int) = 0
        _FresnelAlphaMin("_FresnelAlphaMin",range(0,1)) = 0
        _FresnelAlphaMax("_FresnelAlphaMax",range(0,1)) = 1
// ==================================================
        [Space(10)][Header(DepthMode)]
        [GroupToggle]_ZWriteOn("_ZWriteOn?",int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",int) = 4

        [Space(10)][Header(CullMode)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
// ==================================================

        [Header(Height Cloth FrontSSS BackSSS)]
        _HeightClothSSSMask("_Height(R) , Cloth(G) , SSSMask(B,A)",2d) = "white"{} 

        [Space(10)][Header(FastSSS)]
        [GroupToggle]_SSSOn("_SSSOn",int) = 0
        _FrontSSSIntensity("_FrontSSSIntensity",range(0,1)) = 1
        _FrontSSSColor("_FrontSSSColor",color) = (1,0,0,0)
        _BackSSSIntensity("_BackSSSIntensity",range(0,1)) = 1
        _BackSSSColor("_BackSSSColor",color) = (1,0,0,0)
        [GroupToggle]_AdditionalLightCalcFastSSS("_AdditionalLightCalcFastSSS",int) =0

        [Space(10)][Header(ParallelOffset)]
        [GroupToggle]_ParallalOn("_ParallalOn",int) = 0
        _HeightScale("_HeightScale",range(0.005,0.08)) = 0
// ================================================== kajiya kay
        [Space(10)][Header(Hair)]
        [Header(Strand Spec Mask)]
        _StrandMaskTex("_StrandMaskTex(ao_shift_specMask_tbMask)",2d) = ""{}
	_HairAoIntensity("HairAoIntensity",range(0,1))=1

        [Header(Spec Shift1)]
        _Shift1("_Shift1",float) = 0
        _SpecPower1("_SpecPower1",range(0.01,1)) = 1
        _SpecColor1("_SpecColor1",color) = (1,1,1,1)
        _SpecIntensity1("_SpecIntensity1",float) = 10
        
        [Header(Spec Shift2)]
        _Shift2("_Shift2",float) = 0
        _SpecPower2("_SpecPower2",range(0.01,1)) = 1
        _SpecColor2("_SpecColor2",color) = (1,1,1,1)
        _SpecIntensity2("_SpecIntensity2",float) = 10
// ================================================== ThinFilm
        [Header(Thin Film)]
        [Toggle(_THIN_FILM_ON)]_ThinFilmOn("_ThinFilmOn",float) = 0
        _TFScale("_TFScale",float) = 1
        _TFOffset("_TFOffset",float) = 0
        _TFSaturate("_TFSaturate",range(0,1)) = 1
        _TFBrightness("_TFBrightness",range(0,1)) = 1
        [Header(Mask)]
        [Enum(None,0,MainTexA,1,PbrMaskA,2)]_TFMaskFrom("_TFMaskFrom",int) = 0
        [Enum(None,0,Intensity,1)]_TFMaskUsage("_TFMaskUsage",int) = 0
        [GroupToggle]_TFSpecMask("_TFSpecMask",int) = 0
// ================================================== Debug
        [Header(Debug Info)]
        [Toggle(_POWER_DEBUG)]_EnableDebug("_EnableDebug",float) = 0
        [Header(Debug GI)]
        [GroupToggle]_ShowGIDiff("_ShowGIDiff",float) = 0
        [GroupToggle]_ShowGISpec("_ShowGISpec",float) = 0
        [Header(Debug World Surface)]
        [GroupToggle]_ShowNormal("_ShowNormal",float) = 0
        [GroupToggle]_ShowDiffuse("_ShowDiffuse",float) = 0
        [GroupToggle]_ShowSpecular("_ShowSpecular",float) = 0
        [Header(Debug PBRMask)]
        [GroupToggle]_ShowMetallic("_ShowMetallic",float) = 0
        [GroupToggle]_ShowSmoothness("_ShowSmoothness",float) = 0
        [GroupToggle]_ShowOcclusion("_ShowOcclusion",float) = 0
        // [Header(Stencil)]
        // _StencilRef("_StencilRef",int) = 2
        // [UnityEngine.Rendering.CompareFunction]_StencilComp("_StencilComp",float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend [_SrcMode][_DstMode]
        ZWrite [_ZWriteOn]
        ZTest[_ZTestMode]
        Cull[_CullMode]

        // stencil {
        //     ref [_StencilRef]
        //     comp [_StencilComp]
        // }

        Pass
        {
            Name "PowerPBS"
            // Tags{"LightMode"="ForwardBase" } // drp need this, otherwise shadow out
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            // #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma target 3.0

        //     #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        //     #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma shader_feature_local_fragment _ALPHA_TEST
            #pragma shader_feature_local_fragment _PBRMODE_STANDRAD _PBRMODE_ANISO _PBRMODE_CLOTH _PBRMODE_STRANDSPEC
            #pragma shader_feature_local_fragment _SSSS
            #pragma shader_feature_local_fragment _PRESSS
            #pragma shader_feature_local_fragment _ADDITIONAL_LIGHT
            #pragma shader_feature_local_fragment _CLEARCOAT
            #pragma shader_feature_local_fragment _DIRECTIONAL_LIGHT_FROM_SH
            #pragma shader_feature_local_fragment _DETAIL_MAP
            #pragma shader_feature_local_fragment _SPECULAR_MAP_FLOW
            #pragma shader_feature_local_fragment _THIN_FILM_ON
            #pragma shader_feature_local_fragment _POWER_DEBUG

            #include "Lib/PowerPBSForward.hlsl"
           
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma shader_feature_local_fragment _ALPHA_TEST

            #include "Lib/PowerPBSForward.hlsl"
            ENDHLSL
        }

        Pass{
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHA_TEST

            #include "Lib/ShadowCasterPass.hlsl"
            ENDHLSL
        }


    }
    CustomEditor "PowerUtilities.PowerPBSInspector"
    FallBack "Diffuse"
}
