#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PowerPBS
{
    public class PowerPBSInspector : PowerShaderInspector
    {
        public PowerPBSInspector()
        {
            shaderName = "PowerPBS";
            AlphaTabId = 6;
            RenderQueueTabId = 0;

            OnDrawPropertyFinish += PowerPBSInspector_OnDrawPropertyFinish; ;
        }

        public override void OnClosed(Material material)
        {
            base.OnClosed(material);
            OnDrawPropertyFinish -= PowerPBSInspector_OnDrawPropertyFinish;
        }

        private void PowerPBSInspector_OnDrawPropertyFinish(Dictionary<string, UnityEditor.MaterialProperty> dict, Material mat)
        {
            const string _CustomIBLOn= "_CustomIBLOn";
            if (dict.ContainsKey(_CustomIBLOn))
            {
                var isOn = dict[_CustomIBLOn].floatValue == 1;
                if (!isOn)
                {
                    var cubemap = ReflectionProbe.defaultTexture;
                    if(RenderSettings.defaultReflectionMode == UnityEngine.Rendering.DefaultReflectionMode.Custom)
                    {
                        //cubemap = RenderSettings.customReflection;
                    }
                    mat.SetTexture("_EnvCube", cubemap);
                }
            }

        }
    }
}
#endif