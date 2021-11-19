Shader "Unlit/Testpbr"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Roughness("_Roughness",range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lib/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD1;
                float3 worldNormal:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Roughness,_Metallic;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 l = UnityWorldSpaceLightDir(i.worldPos);
                float3 v = UnityWorldSpaceViewDir(i.worldPos);
                float3 h = normalize(l+v);
                float3 n = normalize(i.worldNormal);

                float4 albedo = tex2D(_MainTex, i.uv);

                BRDFData brdfData = (BRDFData)0;
                InitBRDFData(albedo.xyz,_Roughness,_Metallic,brdfData/**/);

                // sample the texture
                
                float3 directColor = CalcPBS(brdfData,_MainLightColor,_MainLightPosition,n,v);
                return float4(directColor,1);
            }
            ENDHLSL
        }
    }
}
