Shader "Unlit/unityShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE
    // #define SHADOWS_SCREEN
    #include "SAutoLight.cginc"

    float CalcShadowFade(half shadow,float3 worldPos){
        float zDist = dot(_WorldSpaceCameraPos - worldPos, UNITY_MATRIX_V[2].xyz);
        float fadeDist = UnityComputeShadowFadeDistance(worldPos, zDist);
        half  realtimeToBakedShadowFade = UnityComputeShadowFade(fadeDist);
        return lerp(shadow,1,realtimeToBakedShadowFade);
    }

        UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
        #define TRANSFER_SHADOW(a) a._ShadowCoord = mul( unity_WorldToShadow[0], mul( unity_ObjectToWorld, v.vertex ) );
        inline fixed unitySampleShadow (unityShadowCoord4 shadowCoord,float3 worldPos)
        {
            #if defined(SHADOWS_NATIVE)
                fixed shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, shadowCoord.xyz);
                
                shadow = lerp(shadow,1,_LightShadowData.x);
                return CalcShadowFade(shadow,worldPos);
            #endif
        }
        #define SHADOW_ATTENUATION(a) unitySampleShadow(a._ShadowCoord,a.worldPos)
    ENDCG
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            // #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            // #define SHADOWS_SCREEN
            // #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 _ShadowCoord:TEXCOORD1;
                float4 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                TRANSFER_SHADOW(o)
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                return SHADOW_ATTENUATION(i);
            }
            ENDCG
        }
    }
    fallback "Diffuse"
}
