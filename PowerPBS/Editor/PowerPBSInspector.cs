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
        }
    }
}
#endif