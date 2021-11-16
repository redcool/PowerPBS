Shader "Unlit/Testpbr"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Roughness("_Roughness",range(0,1)) = 0.5
    }

HLSLINCLUDE
float MinimalistCookTorrance(float nh,float lh,float rough,float rough2){
    float d = nh * nh * (rough2-1) + 1.00001f;
    float lh2 = lh * lh;
    float spec = rough2/((d*d) * max(0.1,lh2) * (rough*4+2)); // approach sqrt(rough2)
    
    #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
        spec = clamp(spec,0,100);
    #endif
    return spec;
}
ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../Lib/CommonUtils.hlsl"
            

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

            float3 _MainLightPosition;
            float3 _MainLightColor;

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
                float lh = saturate(dot(l,h));
                float nh = saturate(dot(n,h));
                float nl = saturate(dot(n,l));
                float a = _Roughness * _Roughness;
                float a2 = a * a;

                // sample the texture
                float4 albedo = tex2D(_MainTex, i.uv);
                
                float specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                float3 specColor = lerp(0.04,albedo,_Metallic);
                specColor *= specTerm;

                float3 diffColor = lerp(albedo.xyz,specColor,_Metallic);

                float4 col = 1;
                col.rgb = diffColor + specColor;
                return col;
            }
            ENDHLSL
        }
    }
}
