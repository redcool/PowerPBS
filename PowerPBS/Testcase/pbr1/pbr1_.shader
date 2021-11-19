Shader "Unlit/pbr1_"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap("_NormalMap",2d)=""{}
        _NormalScale("_NormalScale",float) = 1
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Roughness("_Roughness",range(0,1)) = 0.5
    }

HLSLINCLUDE
float MinimalistCookTorrance(float nh,float lh,float a,float a2){
    float d = nh * nh * (a2 - 1)+1;
    float vf = max(lh * lh,0.0001);
    float s = a2/(d*d* vf * vf * (4*a+2));
    return s;
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
            #pragma target 3.0
            #include "Lib/Core/CommonUtils.hlsl"
            #include "Lib/Core/TangentLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                TANGENT_SPACE_DECLARE(1,2,3);
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Roughness,_Metallic;

            sampler2D _NormalMap;
            float _NormalScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_COMBINE(v.vertex,v.normal,v.tangent,o/**/);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                TANGENT_SPACE_SPLIT(i);
                float2 mainUV = i.uv;

                float3 tn = UnpackScaleNormal(tex2D(_NormalMap,mainUV),_NormalScale);
                float3 n = TangentToWorld(i.tSpace0,i.tSpace1,i.tSpace2,tn);

                float3 l = _MainLightPosition;
                float3 v = UnityWorldSpaceViewDir(worldPos);
                float3 h = normalize(l+v);
                
                float lh = saturate(dot(l,h));
                float nh = saturate(dot(n,h));
                float nl = saturate(dot(n,l));
                float a = _Roughness * _Roughness;
                float a2 = a * a;

                

                float4 albedo = tex2D(_MainTex, mainUV);

                float radiance = _MainLightColor * nl;
                
                float specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                float3 specColor = lerp(0.04,albedo,_Metallic);
                specColor *= specTerm;

                float3 diffColor = albedo.xyz * (1- _Metallic);
                float3 directColor = (diffColor + specColor) * radiance;

                float4 col = 1;
                col.rgb = directColor;
                return col;
            }
            ENDHLSL
        }
    }
}
