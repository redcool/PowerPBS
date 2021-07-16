#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PowerShader
{
    public class PowerPBSInspector : PowerShaderInspector
    {
        static PowerPBSInspector()
        {
            shaderName = "PowerPBS";
        }
    }
}
#endif