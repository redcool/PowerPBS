Shader "Character/Cartoon_pbr1"
{
    Properties
    {
        [Header(Main )]
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap("_NormalMap",2d) = "bump"{}
        _NormalScale("_NormalScale",float) = 1

        [Header(PBR Mask)]
        _PBRMask("_PBRMask(Metallix:r,Smoothness:g,Occlusion:b)",2d) = "white"{}
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
        _Occlusion("_Occlusion",range(0,1)) = 0

        [Header(Ambient)]
        _DiffuseMin("_DiffuseMin",range(0,1)) = 0.1
        
        [Header(Diffuse Step)]
        _DiffuseStepMin("_DiffuseStepMin",range(0,1)) = 0
        _DiffuseStepMax("_DiffuseStepMax",range(0,1)) = 1

        [Header(PreSSS)]
        [Toggle(_PRESSS)]_ScatterOn("_Scatter",float) = 0
        _ScatterLUT("_ScatterLUT",2d) = "white"{}
        _ScatterCurve("_ScatterCurve",range(0,1)) = 0
        _ScatterIntensity("_ScatterIntensity",float) = 1
        [Toggle]_PreScatterMaskUseMainTexA("_PreScatterMaskUseMainTexA",float) = 0

        [Header(Rim)]
        [Toggle(_RIMON)]_RimOn("_RimOn",int) = 0
        _RimColor("_RimColor",color) = (1,1,1,1)
        _RimStepMin("_RimStepMin",range(0,1)) = 0
        _RimStepMax("_RimStepMax",range(0,1)) = 1

        [Header(Custom Light View)]
        _LightDirOffset("_LightDirOffset",vector)=(0,0,0,0)
        _ViewDirOffset("_ViewDirOffset",vector) = (0,0,0,0)
    }
    SubShader
    {

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local_fragment _PRESSS
            #pragma shader_feature_local_fragment _RIMON

            #include "UnityLib.hlsl"
            #include "BSDF.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                half4 vertex : SV_POSITION;
                float4 tSpace0:TEXCOORD1;
                float4 tSpace1:TEXCOORD2;
                float4 tSpace2:TEXCOORD3;

                half3 tangent:TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.vertex = TransformWorldToHClip(worldPos);
                o.uv = v.uv;

                half3 n = normalize(TransformObjectToWorldNormal(v.normal));
                half3 t = normalize(TransformObjectToWorldDir(v.tangent.xyz));
                half3 b = normalize(cross(n,t)) * v.tangent.w;

                o.tSpace0 = half4(t.x,b.x,n.x,worldPos.x);
                o.tSpace1 = half4(t.y,b.y,n.y,worldPos.y);
                o.tSpace2 = half4(t.z,b.z,n.z,worldPos.z);
                return o;
            }

            sampler2D _MainTex;
            sampler2D _PBRMask;

            half _Smoothness, _Metallic,_Occlusion;


            samplerCUBE unity_SpecCube0;
            half4 unity_SpecCube0_HDR;

            sampler2D _NormalMap;
            half _NormalScale;

            half _DiffuseMin,_DiffuseStepMin,_DiffuseStepMax;

            sampler2D _ScatterLUT;
            half _ScatterCurve,_ScatterIntensity,_PreScatterMaskUseMainTexA;

            half4 _RimColor;
            half _RimStepMin,_RimStepMax;

            half3 _LightDirOffset,_ViewDirOffset;

            half4 frag (v2f i) : SV_Target
            {
                half3 vertexTangent = (half3(i.tSpace0.x,i.tSpace1.x,i.tSpace2.x));
                half3 vertexBinormal = normalize(half3(i.tSpace0.y,i.tSpace1.y,i.tSpace2.y));
                half3 vertexNormal = normalize(half3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));
                half3 tn = UnpackScaleNormal(tex2D(_NormalMap,i.uv),_NormalScale);
 
                half3 n = normalize(half3(
                    dot(i.tSpace0.xyz,tn),
                    dot(i.tSpace1.xyz,tn),
                    dot(i.tSpace2.xyz,tn)
                ));

                half3 worldPos = half3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                half3 l = GetWorldSpaceLightDir(worldPos) + _LightDirOffset;
                half3 v = normalize(GetWorldSpaceViewDir(worldPos) + _ViewDirOffset);
                half3 h = normalize(l+v);
                half nl = saturate(dot(n,l));
                nl = smoothstep(_DiffuseStepMin,_DiffuseStepMax,nl);
                nl = max(_DiffuseMin,nl);

                half nv = saturate(dot(n,v));
                half nh = saturate(dot(n,h));
                half lh = saturate(dot(l,h));

                // pbrmask
                half4 pbrMask = tex2D(_PBRMask,i.uv);

                half smoothness = _Smoothness * pbrMask.y;
                half roughness = 1 - smoothness;
                half a = max(roughness * roughness, HALF_MIN_SQRT);
                half a2 = max(a * a ,HALF_MIN);

                half metallic = _Metallic * pbrMask.x;
                half occlusion = lerp(1,pbrMask.b,_Occlusion);

                half4 mainTex = tex2D(_MainTex, i.uv);
                half3 albedo = mainTex.xyz;
                half alpha = mainTex.w;

                half3 diffColor = albedo * (1-metallic);
                half3 specColor = lerp(0.04,albedo,metallic);

                half3 sh = SampleSH(n);
                half3 giDiff = sh * diffColor;

                half mip = roughness * (1.7 - roughness * 0.7) * 6;
                half3 reflectDir = reflect(-v,n);
                half4 envColor = texCUBElod(unity_SpecCube0,half4(reflectDir,mip));
                envColor.xyz = DecodeHDREnvironment(envColor,unity_SpecCube0_HDR);

                half surfaceReduction = 1/(a2+1);
                
                half grazingTerm = saturate(smoothness + metallic);
                half fresnelTerm = Pow4(1-nv);
                half3 giSpec = surfaceReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);
                half4 col = 0;
                col.xyz = (giDiff + giSpec) * occlusion;

                half3 radiance = nl * _MainLightColor.xyz;
                half specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                col.xyz += (diffColor + specColor * specTerm) * radiance;

                // pre sss
                #if defined(_PRESSS)
                half3 presss = PreScattering(_ScatterLUT,n,l,_MainLightColor.xyz,nl,half4(albedo,alpha),worldPos,_ScatterCurve,_ScatterIntensity,_PreScatterMaskUseMainTexA);
                col.xyz += presss;
                #endif

                #if defined(_RIMON)
                half rim = 1 - nv;
                rim = rim * rim;
                rim = smoothstep(_RimStepMin,_RimStepMax,rim);
                half3 rimColor =  rim * nl * _RimColor;
                col.xyz += rimColor;
                #endif

                return col;
            }
            ENDHLSL
        }
    }
}
