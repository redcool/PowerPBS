using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class LightingProcess : MonoBehaviour
{
    public Light lightComp;
    public bool revertLightDir = true;
    [Header("Performance")]
    public bool blinnOn = true;
    public bool normalMapOn = true;
    public bool fogOn = true;
    public bool islowSetting;

    [Header("Main Light Params")]
    [SerializeField] Vector4 lightDir = new Vector4(0,0.3f,0,0);
    [SerializeField] Vector4 lightColor = Vector4.one;

    [Header("Other Params")]
    [Range(0.01f,1)]public float shadowIntensityInLightmap;
    [SerializeField] Color ambientColor = new Color(.2f, .2f, .2f);
    [SerializeField] [Range(0, 1)] float shadowStrength = 1;
    [SerializeField] [Range(0, 1)] float shadowEdge = 1;
    [Range(0, 1)] public float lightingType = 0.5f;

    public static LightingProcess Instance { private set; get; }

    public static event Action<LightingProcess> OnSetupParameters;

    // Start is called before the first frame update
    void Awake()
    {
        lightComp = GetComponent<Light>();

        if (Instance != null)
        {
            //enabled = false;
            
            //if(lightComp)
            //    lightComp.enabled = false;

            return;
        }

        Instance = this;
    }

    void OnDestroy()
    {
        //OnSetupParameters = null;
        Instance = null;
    }

    //#if UNITY_EDITOR
    // Update is called once per frame
    private void Update()
    {
        SetupParameters();
        SendToShader();
    }
    //#endif
    void OnEnable()
    {
        SetupParameters();
        SendToShader();
    }

    void OnDisable()
    {
        if (!Instance || Instance != this)
            return;

        lightDir = default(Vector4);
        lightColor = default(Color);
        SendToShader();
    }
    private void SetupParameters()
    {
        lightDir = transform.forward;
        if (revertLightDir)
        {
            lightDir *= -1;
        }
        if (lightComp)
            lightColor = lightComp.color * lightComp.intensity;
        //lightShadowIntensity = lightComp.shadowStrength;
    }

     void SendToShader()
    {
        if (OnSetupParameters != null)
            OnSetupParameters(this);

        Shader.SetGlobalVector("_MainLightDir", lightDir);
        Shader.SetGlobalColor("_MainLightColor", lightColor);
        Shader.SetGlobalFloat("_MainLightShadowIntensity", shadowIntensityInLightmap);
        Shader.SetGlobalColor("_AmbientColor", ambientColor);
        Shader.SetGlobalFloat("_ShadowStrength", shadowStrength);
        Shader.SetGlobalFloat("_ShadowEdge", shadowEdge);
        Shader.SetGlobalFloat("_LightingType", lightingType);

        //OpenKeyword("NORMAL_MAP_ON", normalMapOn);
        //OpenKeyword("BLINN_ON", blinnOn);
        //OpenKeyword("FOG_ON", fogOn);
        //Shader.SetGlobalInt("_FogOn", fogOn ? 1 : 0);
        //Shader.SetGlobalInt("_RainReflectionOn", rainReflectionOn ? 1 : 0);
        Shader.SetGlobalInt("_NormalMapOn", normalMapOn ? 1 : 0);
        Shader.SetGlobalInt("_BlinnOn", blinnOn ? 1 : 0);
        OpenKeyword("LOW_SETTING", islowSetting);
    }

    void OpenKeyword(string key,bool isOn)
    {
        if (Shader.IsKeywordEnabled(key) == isOn)
            return;

        if (isOn)
            Shader.EnableKeyword(key);
        else
            Shader.DisableKeyword(key);
    }



    public void OpenNormalMap(bool isOn)
    {
        normalMapOn = isOn;
        SendToShader();
    }
    public void OpenBlinn(bool isOn)
    {
        blinnOn = isOn;
        SendToShader();
    }

    public void OpenFog(bool isOn)
    {
        fogOn = isOn;
        SendToShader();
    }

    public void OpenLowSetting(bool isOn)
    {
        islowSetting = isOn;
        SendToShader();
    }
    public void OnSystemSettingChange()
    {
        SendToShader();
    }
}
