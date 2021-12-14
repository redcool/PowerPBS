Shader "Hidden/pbr1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap("_NormalMap",2d) = "bump"{}
        _NormalScale("_NormalScale",float) = 1

        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
    }
    SubShader
    {

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityLib.hlsl"

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
                float4 tSpace0:TEXCOORD1;
                float4 tSpace1:TEXCOORD2;
                float4 tSpace2:TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float3 worldPos = TransformObjectToWorld(v.vertex);
                float3 n = TransformObjectToWorldNormal(v.normal);
                o.vertex = TransformWorldToHClip(worldPos);
                o.uv = v.uv;

                float3 t = TransformObjectToWorld(v.tangent);
                float3 b = cross(n,t) * v.tangent.w;

                o.tSpace0 = float4(t.x,b.x,n.x,worldPos.x);
                o.tSpace1 = float4(t.y,b.y,n.y,worldPos.y);
                o.tSpace2 = float4(t.z,b.z,n.z,worldPos.z);
                return o;
            }

            sampler2D _MainTex;
            half _Smoothness;
            half _Metallic;

            samplerCUBE unity_SpecCube0;
            half4 unity_SpecCube0_HDR;

            sampler2D _NormalMap;
            float _NormalScale;

            half4 frag (v2f i) : SV_Target
            {
                float3 vertexNormal = normalize(float3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));
                
                float3 tn = UnpackScaleNormal(tex2D(_NormalMap,i.uv),_NormalScale);
                float3 n = normalize(float3(
                    dot(half3(i.tSpace0.xyz),tn),
                    dot(half3(i.tSpace1.xyz),tn),
                    dot(half3(i.tSpace2.xyz),tn)
                ));


                float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                float3 l = GetWorldSpaceLightDir(worldPos);
                float3 v = normalize(GetWorldSpaceViewDir(worldPos));
                float3 h = normalize(l+v);
                float nl = saturate(dot(n,l));
                float nv = saturate(dot(n,v));
                float nh = saturate(dot(n,h));
                float lh = saturate(dot(l,h));

                float smoothness = _Smoothness;
                float roughness = 1 - smoothness;
                float a = max(roughness * roughness, HALF_MIN_SQRT);
                float a2 = max(a * a ,HALF_MIN);

                float metallic = _Metallic;

                half4 mainTex = tex2D(_MainTex, i.uv);
                half albedo = mainTex.xyz;
                half alpha = mainTex.w;

                half3 diffColor = albedo * (1-metallic);
                half3 specColor = lerp(0.04,albedo,metallic);

                half3 sh = SampleSH(n);
                half3 giDiff = sh * diffColor;

                half mip = roughness * (1.7 - roughness * 0.7) * 6;
                half3 reflectDir = reflect(-v,n);
                half4 envColor = texCUBElod(unity_SpecCube0,half4(reflectDir,mip));
                envColor.xyz = DecodeHDREnvironment(envColor,unity_SpecCube0_HDR);

                half surfaceReduction = saturate(smoothness + metallic);
                half grazingTerm = 1/(a2+1);
                half fresnelTerm = Pow4(1-nv);
                half3 giSpec = surfaceReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);

                float4 col = 0;
                col.xyz = giDiff + giSpec;

                half3 radiance = nl * _MainLightColor;
                half specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                col.xyz += (diffColor + specColor * specTerm) * radiance;
                
                return col;
            }
            ENDHLSL
        }
    }
}
