using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DiffuseProfileSetter : MonoBehaviour
{
    public Color mainColor = Color.white;
    public Color fallColor = Color.red;
    private void OnEnable()
    {
        SendKernels();
    }
    public void SendKernels()
    {
        var kernels = new List<Vector4>();
        var strength = new Vector3(mainColor.r, mainColor.g, mainColor.b);
        var falloff = new Vector3(fallColor.r, fallColor.g, fallColor.b);
        SSSSKernel.CalculateKernel(kernels, 25, strength, falloff);
        Shader.SetGlobalVectorArray("_Kernel",kernels);
    }

#if UNITY_EDITOR
    private void Update()
    {
        SendKernels();
    }
#endif

}
