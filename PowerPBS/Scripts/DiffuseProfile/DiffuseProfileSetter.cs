using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DiffuseProfileSetter : MonoBehaviour
{
    public Color strength = Color.white;
    public Color falloff = Color.red;
    private void OnEnable()
    {
        SendKernels();
    }
    public void SendKernels()
    {
        var kernels = new List<Vector4>();
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
