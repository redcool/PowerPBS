namespace PowerUtilities.PowerPBS
{
    using System;
    using Unity.Collections;
    using UnityEngine;
    using UnityEngine.Rendering;
    using UnityEngine.Rendering.Universal;

    /// <summary>
    /// Update Drp's Light & shadow shader variables
    /// </summary>
    public static class DrpLightShaderVarables
    {

        // drp light datas
        public static readonly int _LightColor0;
        public static readonly int _WorldSpaceLightPos0;
        public static readonly int _MainLightShadowmapTexture;
        public static readonly int _ShadowBias;
        public static readonly int _MainLightShadowOn;

        static DrpLightShaderVarables()
        {
            _LightColor0 = Shader.PropertyToID("_LightColor0");
            _WorldSpaceLightPos0 = Shader.PropertyToID("_WorldSpaceLightPos0");
            _MainLightShadowmapTexture = Shader.PropertyToID("_MainLightShadowmapTexture");

            _ShadowBias = Shader.PropertyToID("unity_LightShadowBias");
            _MainLightShadowOn = Shader.PropertyToID("_MainLightShadowOn");
        }

        public static void SendLight(CommandBuffer cmd, RenderingData renderingData)
        {
            var lightData = renderingData.lightData;
            if (lightData.mainLightIndex < 0)
                return;



            // light
            var vLight = lightData.visibleLights[lightData.mainLightIndex];
            cmd.SetGlobalVector(_WorldSpaceLightPos0, -vLight.localToWorldMatrix.GetColumn(2));
            cmd.SetGlobalColor(_LightColor0, vLight.finalColor);

            // shadow bias
            var shadowData = renderingData.shadowData;
            var shadowResolution = ShadowUtils.GetMaxTileResolutionInAtlas(shadowData.mainLightShadowmapWidth, shadowData.mainLightShadowmapHeight, shadowData.mainLightShadowCascadesCount);
            Matrix4x4 viewMat, projMat;
            ShadowSplitData shadowSplitData;
            renderingData.cullResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(lightData.mainLightIndex, 0, shadowData.mainLightShadowCascadesCount, shadowData.mainLightShadowCascadesSplit, shadowResolution, vLight.light.shadowNearPlane, out viewMat, out projMat, out shadowSplitData);

            Vector4 shadowBias = ShadowUtils.GetShadowBias(ref vLight, lightData.mainLightIndex, ref renderingData.shadowData, projMat, shadowResolution);

            cmd.SetGlobalVector(_ShadowBias, shadowBias);

            var asset = UniversalRenderPipeline.asset;
            cmd.SetGlobalFloat(_MainLightShadowOn, asset.supportsMainLightShadows ? 1 : 0);
        }
    }

    /// <summary>
    /// update PowerLit.shader's variables
    /// </summary>
    public static class PowerLitShaderVariables
    {

        //const string MAIN_LIGHT_MODE_ID = "_MainLightMode";
        //const string ADDITIONAL_LIGHT_MODE_ID = "_AdditionalLightMode";

        public static readonly int _MainLightMode,
            _AdditionalLightMode,
            _MainLightShadowCascadeOn,
            _LightmapOn,
            _Shadows_ShadowMaskOn,
            _MainLightShadowOn
            ;

        static PowerLitShaderVariables()
        {
            _MainLightMode = Shader.PropertyToID("_MainLightMode");
            _AdditionalLightMode = Shader.PropertyToID("_AdditionalLightMode");
            _MainLightShadowCascadeOn = Shader.PropertyToID("_MainLightShadowCascadeOn");
            _LightmapOn = Shader.PropertyToID("_LightmapOn");
            _Shadows_ShadowMaskOn = Shader.PropertyToID("_Shadows_ShadowMaskOn");
            _MainLightShadowOn = Shader.PropertyToID("_MainLightShadowOn");
        }


        public static void SendParams(CommandBuffer cmd, PowerURPLitFeatures.Settings settings,ref RenderingData renderingData)
        {
            var asset = UniversalRenderPipeline.asset;
            var mainLightCastShadows = renderingData.shadowData.supportsMainLightShadows;
            

            cmd.SetGlobalInt(_MainLightShadowCascadeOn, asset.shadowCascadeCount > 1 ? 1 : 0);
            cmd.SetGlobalInt(_LightmapOn, settings._LightmapOn ? 1 : 0);
            cmd.SetGlobalInt(_Shadows_ShadowMaskOn, settings._Shadows_ShadowMaskOn ? 1 : 0);
            cmd.SetGlobalInt(_MainLightShadowOn, mainLightCastShadows ? 1 : 0);
            cmd.SetGlobalInt(_MainLightMode, (int)asset.mainLightRenderingMode);
            cmd.SetGlobalInt(_AdditionalLightMode, (int)asset.additionalLightsRenderingMode);
        }
    }


    public class PowerURPLitFeatures : ScriptableRendererFeature
    {

        [Serializable]
        public struct Settings
        {
            //public bool isActive;
            //[Header("Main Light Shadow")]
            //[NonSerialized] public bool _MainLightShadowOn;
            //[NonSerialized] public bool _MainLightShadowCascadeOn;
            //[NonSerialized] public bool _AdditionalVertexLightOn;

            [Tooltip("enabled lightmap ?")] public bool _LightmapOn;
            [Tooltip("enable shadowMask ?")] public bool _Shadows_ShadowMaskOn;

            public bool updateDRPShaderVarables;
        }

        class PowerURPLitUpdateParamsPass : ScriptableRenderPass
        {
            public Settings settings;

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                PowerLitShaderVariables.SendParams(cmd,settings,ref renderingData);
                if (settings.updateDRPShaderVarables)
                {
                    DrpLightShaderVarables.SendLight(cmd, renderingData);
                }
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {

            }
        }
        public Settings settings = new Settings();
        PowerURPLitUpdateParamsPass pass;


        /// <inheritdoc/>
        public override void Create()
        {
            pass = new PowerURPLitUpdateParamsPass();
            pass.settings = settings;
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(pass);
        }
    }


}