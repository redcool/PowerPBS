// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

/**
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
        [Space(20)][Header(MainProp)]
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color("Color",color) = (1,1,1,1)
        
        _NormalMap("NormalMap",2d) = "bump"{}
        _NormalMapScale("_NormalMapScale",range(0,5)) = 1

        [noscaleoffset]_MetallicMap("Metallic(R),Smoothness(G),Occlusion(B)",2d) = "white"{}
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("Smoothness",range(0,1)) = 0
        _Occlusion("_Occlusion",range(0,1)) = 1

        [Header(PBR Mode)]
        [Enum(Standard,0,Aniso,1,Cloth,2,StrandSpec,3)]_PBRMode("_PBRMode",int) = 0
        [Header(Light Options)]
        [Toggle]_SpecularOn("_SpecularOn",float) = 1
        _FresnelIntensity("_FresnelIntensity",range(1,3)) = 1
// ==================================================
        [Space(10)][Header(Shadow)]
        [Toggle]_ApplyShadowOn("_ApplyShadowOn",int) = 1

        [Header(URP Additional Lights)]
        [Toggle]_ReceiveAdditionalLightsOn("_ReceiveAdditionalLightsOn",int) = 1
        [Toggle]_ReceiveAdditionalLightsShadowOn("_ReceiveAdditionalLightsShadowOn",int) = 1
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
        [Header(ScatterLUT)]
        [Toggle]_ScatteringLUTOn("_ScatteringLUTOn",float) = 0
        [NoScaleOffset]_ScatteringLUT("_ScatteringLUT",2d) = ""{}
        _ScatteringIntensity("_ScatteringIntensity",range(0,3)) = 1
        _CurvatureScale("_CurvatureScale (MainTex.a)",range(0.01,0.99)) = 1
        [Toggle]_LightColorNoAtten("_LightColorNoAtten",int) = 1
        [Toggle]_AdditionalLightCalcScatter("_AdditionalLightCalcScatter",int) = 0
// ==================================================
        [Header(Cloth Spec)]
        [hdr]_ClothSheenColor("_ClothSheenColor",Color) = (1,1,1,1)
        _ClothDMin("_ClothDMin",range(0,1)) = 0
        _ClothDMax("_ClothDMax",range(0,1)) = 1
        [Toggle]_ClothGGXUseMainTexA("_ClothGGXUseMainTexA",int) = 0

// ==================================================
		[Space(10)][Header(Detail4_Map Top Layer)]
		[Toggle]_Detail4_MapOn("_Detail4_MapOn",int) = 0
		[Enum(Multiply,0,Replace,1)]_Detail4_MapMode("_Detail4_MapMode",int) = 0
		_Detail4_Map("_Detail4_Map(RGB),Detail4_Mask(A)",2d) = "white"{}
		_Detail4_MapIntensity("_Detail4_MapIntensity",range(0,1)) = 1
		/*_Detail4_NormalMap("_Detail4_NormalMap",2d) = "bump"{}
		_Detail4_NormalMapScale("_Detail4_NormalMapScale",range(0,5)) = 1*/
		[Space(10)][Header(Detail3_Map)]
		[Toggle]_Detail3_MapOn("_Detail3_MapOn",int) = 0
		[Enum(Multiply,0,Replace,1)]_Detail3_MapMode("_Detail3_MapMode",int) = 0
		_Detail3_Map("_Detail3_Map(RGB),Detail3_Mask(A)",2d) = "white"{}
		_Detail3_MapIntensity("_Detail3_MapIntensity",range(0,1)) = 1
		/*_Detail3_NormalMap("_Detail3_NormalMap",2d) = "bump"{}
		_Detail3_NormalMapScale("_Detail3_NormalMapScale",range(0,5)) = 1*/
		[Space(10)][Header(Detail2_Map)]
		[Toggle]_Detail2_MapOn("_Detail2_MapOn",int) = 0
        [Enum(Multiply,0,Replace,1)]_Detail2_MapMode("_Detail2_MapMode",int) = 0
		_Detail2_Map("_Detail2_Map(RGB),EyeMask(A)",2d) = "white"{}
		_Detail2_MapIntensity("_Detail2_MapIntensity",range(0,1)) = 1
		/*_Detail2_NormalMap("_Detail2_NormalMap",2d) = "bump"{}
		_Detail2_NormalMapScale("_Detail2_NormalMapScale",range(0,5)) = 1*/
		[Space(10)][Header(Detail1_Map)]
		[Toggle]_Detail1_MapOn("_Detail1_MapOn",int) = 0
        [Enum(Multiply,0,Replace,1)]_Detail1_MapMode("_Detail1_MapMode",int) = 0
		_Detail1_Map("_Detail1_Map(rgb),MouthMask(A)",2d) = "white"{}
		_Detail1_MapIntensity("_Detail1_MapIntensity",range(0,1)) = 1
		/*_Detail1_NormalMap("_Detail1_NormalMap",2d) = "bump"{}
		_Detail1_NormalMapScale("_Detail1_NormalMapScale",range(0,5)) = 1*/
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
        [Space(10)][Header(Indirect Diffuse)]
        _IndirectIntensity("_IndirectIntensity",float) = 1
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
// ==================================================
        [Space(10)][Header(DepthMode)]
        [Toggle]_ZWriteOn("_ZWriteOn?",int) = 1

        [Space(10)][Header(CullMode)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
// ==================================================

        [Header(Height Cloth FrontSSS BackSSS)]
        _HeightClothSSSMask("_Height(R) , Cloth(G) , SSSMask(B,A)",2d) = "white"{} 

        [Space(10)][Header(FastSSS)]
        [Toggle]_SSSOn("_SSSOn",int) = 0
        _FrontSSSIntensity("_FrontSSSIntensity",range(0,1)) = 1
        _FrontSSSColor("_FrontSSSColor",color) = (1,0,0,0)
        _BackSSSIntensity("_BackSSSIntensity",range(0,1)) = 1
        _BackSSSColor("_BackSSSColor",color) = (1,0,0,0)
        [Toggle]_AdditionalLightCalcFastSSS("_AdditionalLightCalcFastSSS",int) =0

        [Space(10)][Header(ParallelOffset)]
        [Toggle]_ParallalOn("_ParallalOn",int) = 0
        _Height("_Height",range(0.005,0.08)) = 0
// ==================================================
        [Space(10)][Header(Hair)]
        [Header(Tangent Binormal Mask Map)]
        _TBMaskMap("_TBMaskMap(R,white:use binormal)",2d) = "white"{}

        [Header(Tangent Shift)]
        _ShiftTex("_ShiftTex(g:shift,b:mask)",2d) = ""{}
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
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 431
        Blend [_SrcMode][_DstMode]
        ZWrite [_ZWriteOn]
        Cull[_CullMode]

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
            #include "PowerPBSForward.cginc"
           
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
            #include "PowerPBSShadowCasterPass.cginc"
            ENDCG
        }
    }
    CustomEditor "PowerPBS.PowerPBSInspector"
    FallBack "Diffuse"
}
