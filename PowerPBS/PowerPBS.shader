﻿/**
    pbs渲染流程
    1 简化了gi(diffuse,specular)
    2 Lighting里baked模式下同LightingProcess传递光照信息

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
        
        [Header(PBR Mask Channel)]
        [Enum(R,0,G,1,B,2,A,3)]_MetallicChannel("_MetallicChannel",float) = 0
        [Enum(R,0,G,1,B,2,A,3)]_SmoothnessChannel("_SmoothnessChannel",float) = 1
        [Enum(R,0,G,1,B,2,A,3)]_OcclusionChannel("_OcclusionChannel",float) = 2

        [Header(Custom Specular)]
        [Toggle]_CustomSpecularMapOn("_CustomSpecularMapOn",int) = 0
        _CustomSpecularMap("_CustomSpecularMap(a:Mask(0:DielectricSpec,1:CustomSpecColor))",2d) ="white"{}
        _CustomSpecularIntensity("_CustomSpecularIntensity",float) = 1
        
        [Header(Clear Coat)]
        [Toggle]_ClearCoatOn("_ClearCoatOn",int) = 0
        _ClearCoatSpecColor("_ClearCoatSpecColor",color) = (1,1,1,1)
        _CoatSmoothness("_CoatSmoothness",range(0,1)) = 0.5

// ================================================== vertex
        [Header(Vertex Scale)]
        _VertexScale("_VertexScale",range(-0.1,0.1)) = 0
        [Toggle]_VertexColorRAttenOn("_VertexColorRAttenOn(R)",int) = 1
// ================================================== Settings
        [Header(PBR Mode)]
        [Enum(Standard,0,Aniso,1,Cloth,2,StrandSpec,3)]_PBRMode("_PBRMode",int) = 0

        [Header(Specular Options)]
        [Toggle]_SpecularOn("_SpecularOn",float) = 1
        _FresnelIntensity("_FresnelIntensity",range(0,3)) = 1
        _MaxSpecularIntensity("_MaxSpecularIntensity", range(0, 10)) = 5
// ==================================================
        [Space(10)][Header(Shadow)]
        [Toggle]_ApplyShadowOn("_ApplyShadowOn",int) = 1

        [Header(URP Additional Lights)]
        [Toggle]_ReceiveAdditionalLightsOn("_ReceiveAdditionalLightsOn",int) = 1
        [Toggle]_ReceiveAdditionalLightsShadowOn("_ReceiveAdditionalLightsShadowOn",int) = 1
        [Toggle]_AdditionalLightSoftShadowOn("_AdditionalLightSoftShadowOn",int) = 0

        [Header(Spherical Harmonics)]
        [Toggle]_DirectionalLightFromSHOn("_DirectionalLightFromSHOn",int) = 0
        _AmbientSHIntensity("_AmbientSHIntensity",range(0,1)) = 0.5
        _DirectionalSHIntensity("_DirectionalSHIntensity", range(0, 1)) = 0.5
// ==================================================
        [Header(Anisotropic)]
        _AnisoColor("_AnisoColor",color) = (1,1,0,1)
        _AnisoIntensity("_AnisoIntensity",float) = 1
        _AnisoRough("_AnisoRough",range(-1,1)) = 0
        // ---- layer2
        [Header(Aniso2)]
        [Toggle]_AnisoLayer2On("_AnisoLayer2On",int) = 0
        _Layer2AnisoColor("_Layer2AnisoColor",color) = (.5,0,0,0)
        _Layer2AnisoIntensity("_Layer2AnisoIntensity",float) = 1
        _Layer2AnisoRough("_Layer2AnisoRough",range(-1,1)) = 0
        [Header(Mask)]
        [Toggle]_AnisoMaskUseMainTexA("_AnisoMaskUseMainTexA",float) = 0
// ==================================================
        [Header(Pre Integral Scatter)]
        [Toggle]_ScatteringLUTOn("_ScatteringLUTOn",float) = 0
        [NoScaleOffset]_ScatteringLUT("_ScatteringLUT",2d) = ""{}
        _ScatteringIntensity("_ScatteringIntensity",range(0,3)) = 1
        _CurvatureScale("_CurvatureScale (MainTex.a)",range(0.01,0.99)) = 1
        [Toggle]_LightColorNoAtten("_LightColorNoAtten",int) = 1
        [Toggle]_AdditionalLightCalcScatter("_AdditionalLightCalcScatter",int) = 0

        [Header(Diffuse Profile ScreenSpace)]
        [Toggle]_DiffuseProfileOn("_DiffuseProfileOn",int) = 0
        _BlurSize("_BlurSize",range(0,20)) = 1
        [Toggle]_DiffuseProfileMaskUserMainTexA("_DiffuseProfileMaskUserMainTexA",int) = 1
// ==================================================
        [Header(Cloth Spec)]
        [hdr]_ClothSheenColor("_ClothSheenColor",Color) = (1,1,1,1)
        _ClothDMin("_ClothDMin",range(0,1)) = 0
        _ClothDMax("_ClothDMax",range(0,1)) = 1
        [Toggle]_ClothGGXUseMainTexA("_ClothGGXUseMainTexA",int) = 0

// ==================================================
        // [Toggle]_Detail4_MapOn("_Detail4_MapOn",int) = 0
        // [Enum(Multiply,0,Replace,1)]_Detail4_MapMode("_Detail4_MapMode",int) = 0
        // _Detail4_Map("_Detail4_Map(RGB),Detail4_Mask(A)",2d) = "white"{}
        // _Detail4_MapIntensity("_Detail4_MapIntensity",range(0,1)) = 1

        // [Space(10)][Header(Detail3_Map)]
        // [Toggle]_Detail3_MapOn("_Detail3_MapOn",int) = 0
        // [Enum(Multiply,0,Replace,1)]_Detail3_MapMode("_Detail3_MapMode",int) = 0
        // _Detail3_Map("_Detail3_Map(RGB),Detail3_Mask(A)",2d) = "white"{}
        // _Detail3_MapIntensity("_Detail3_MapIntensity",range(0,1)) = 1

        [Space(10)][Header(Detail2_Map)]
        [Toggle]_Detail2_MapOn("_Detail2_MapOn",int) = 0
        [Enum(Multiply,0,Replace,1)]_Detail2_MapMode("_Detail2_MapMode",int) = 0
        _Detail2_Map("_Detail2_Map(RGB),EyeMask(A)",2d) = "white"{}
        _Detail2_MapIntensity("_Detail2_MapIntensity",range(0,1)) = 1

        [Space(10)][Header(Detail1_Map)]
        [Toggle]_Detail1_MapOn("_Detail1_MapOn",int) = 0
        [Enum(Multiply,0,Replace,1)]_Detail1_MapMode("_Detail1_MapMode",int) = 0
        _Detail1_Map("_Detail1_Map(rgb),MouthMask(A)",2d) = "white"{}
        _Detail1_MapIntensity("_Detail1_MapIntensity",range(0,1)) = 1

        [Space(10)][Header(DetailMap Bottom Layer)]
        [Toggle]_Detail_MapOn("_Detail_MapOn",int) = 0
        [Enum(Multiply,0,Replace,1)]_Detail_MapMode("_Detail_MapMode",int) = 0
        _Detail_Map("_Detail_Map(RGB),DetailMask(A)",2d) = "white"{}
        _Detail_MapIntensity("_Detail_MapIntensity",range(0,1)) = 1
        _Detail_NormalMap("_Detail_NormalMap",2d) = "bump"{}
        _Detail_NormalMapScale("_Detail_NormalMapScale",range(0,5)) = 1
 // ==================================================       
        [Space(10)][Header(Custom IBL)]
        [Toggle]_CustomIBLOn("_CustomIBLOn",float) = 0
        [noscaleoffset]_EnvCube("_EnvCube",cube) = "white"{}
        _EnvIntensity("_EnvIntensity",float) = 1
        _ReflectionOffsetDir("_ReflectionOffsetDir",vector) = (0,0,0,0)
// ==================================================
        [Space(10)][Header(Emission)]
        [Toggle]_EmissionOn("_EmissionOn",float) = 0
        [noscaleoffset]_EmissionMap("_EmissionMap(RGB),EmissionMask(A)",2d) = "white"{}
        [hdr]_EmissionColor("_EmissionColor",color) = (1,1,1,1)
        _Emission("_Emission",float) = 1
// ==================================================
        [Space(10)][Header(GI )]
        _IndirectSpecularIntensity("_IndirectSpecularIntensity",float) = 1
        _BackFaceGIDiffuse("_BackFaceGIDiffuse",range(0,1)) = 0
// ==================================================
        [Space(10)][Header(CustomLight)]
        [Toggle]_CustomLightOn("_CustomLightOn",int) = 0
        _LightDir("_LightDir",vector) = (0,0.5,0,0)
        _LightColor("_LightColor",color) = (1,1,1,1)
// ==================================================
        [Space(10)][Header(AlphaTest)]
        [Toggle]_AlphaTestOn("_AlphaTestOn",int) = 0
        _Cutoff("_Cutoff",range(0,1)) = 0.5

        [Space(10)][Header(AlphaBlendMode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0

        [Space(10)][Header(AlphaMultiMode)]
        [Toggle]_AlphaPreMultiply("_AlphaPreMultiply",int) = 0

        [Header(Fresnel affect)]
        [Toggle]_FresnelAlphaOn("_FresnelAlphaOn",int) = 0
        _FresnelMin("_FresnelMin",range(0,1)) = 0
        _FresnelMax("_FresnelMax",range(0,1)) = 1
// ==================================================
        [Space(10)][Header(DepthMode)]
        [Toggle]_ZWriteOn("_ZWriteOn?",int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",int) = 4

        [Space(10)][Header(CullMode)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
// ==================================================

        [Header(Height FastSSS Mask)]
        _HeightClothSSSMask("_Height(R) , unused(G) , SSSMask(B,A)",2d) = "white"{} 

        [Space(10)][Header(FastSSS)]
        [Toggle]_SSSOn("_SSSOn",int) = 0
        _FrontSSSIntensity("_FrontSSSIntensity",range(0,1)) = 1
        _FrontSSSColor("_FrontSSSColor",color) = (1,0,0,0)
        _BackSSSIntensity("_BackSSSIntensity",range(0,1)) = 1
        _BackSSSColor("_BackSSSColor",color) = (1,0,0,0)
        [Toggle]_AdditionalLightCalcFastSSS("_AdditionalLightCalcFastSSS",int) =0

        [Space(10)][Header(ParallelOffset)]
        [Toggle]_ParallalOn("_ParallalOn",int) = 0
        _HeightScale("_HeightScale",range(0.005,0.08)) = 0
// ==================================================
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

        // [Header(Stencil)]
        // _StencilRef("_StencilRef",int) = 2
        // [UnityEngine.Rendering.CompareFunction]_StencilComp("_StencilComp",float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 431
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
            // Tags{"LightMode"="ForwardBase" } // drp need this, otherwise shadow out
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            // #pragma multi_compile_fwdbase
            #pragma target 3.0
            #define UNITY_BRDF_PBS BRDF1_Unity_PBS
            #define PBS1

            #define URP_SHADOW // for urp 
            // #define SRP_BATCHER
            #include "Lib/PowerPBSForward.cginc"
           
            ENDCG
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ZTest LEqual
            ColorMask 0

            CGPROGRAM
            #pragma exclude_renderers gles gles3 glcore

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Lib/PowerPBSForward.cginc"
            ENDCG
        }

        Pass{
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define URP_SHADOW
            // #define SRP_BATCHER
            #include "Lib/PowerPBSShadowCasterPass.cginc"
            ENDCG
        }


    }
    CustomEditor "PowerPBS.PowerPBSInspector"
    FallBack "Diffuse"
}
