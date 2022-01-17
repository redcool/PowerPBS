namespace PowerPBS
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;

    [ExecuteInEditMode]
    public class DiffuseProfileSetter : MonoBehaviour
    {
        [Header("Main")]
        public Color strength = Color.white;
        [Min(0.1f)]public float strengthIntensity = 0.1f;
        
        [Header("Falloff")]
        public Color falloff = Color.red;
        [Min(0.01f)]public float falloffIntensity = 0.1f;

        private void OnEnable()
        {
            SendKernels();
        }
        public void SendKernels()
        {
            var kernels = new List<Vector4>();
            SSSSKernel.CalculateKernel(kernels, 25, strength * strengthIntensity, falloff * falloffIntensity);
            Shader.SetGlobalVectorArray("_Kernel", kernels);
        }

#if UNITY_EDITOR
        private void Update()
        {
            SendKernels();
        }
#endif

    }
}