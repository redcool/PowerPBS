using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
[CustomEditor(typeof(DiffuseProfileSetter))]
public class DiffuseProfileSetterEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        var inst = target as DiffuseProfileSetter;
        if (GUILayout.Button("send"))
        {
            inst.SendKernels();
        }
    }
}
#endif

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
