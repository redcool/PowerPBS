Shader "Unlit/pbr1_"
{
    /*
    lighting(pbr,charlie,aniso)
    shadow(main light)
    fog
    detail()
    alpha
    srp batched (instanced)

    */
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _NormalMap("_NormalMap",2d)=""{}
        _NormalScale("_NormalScale",float) = 1

        _PbrMask("_PbrMask",2d)=""{}

        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
        _Occlusion("_Occlusion",range(0,1)) = 0

        [Toggle]_SpecularOn("_SpecularOn",int) = 1

        [Enum(PBR,0,Aniso,1,Charlie,2)]_PbrMode("_PbrMode",int) = 0
        _AnisoRough("_AnisoRough",range(-.5,.5)) = 0
    }

HLSLINCLUDE
#include "Lib/Core/CommonUtils.hlsl"
#include "Lib/Core/TangentLib.hlsl"
#include "Lib/Core/BSDF.hlsl"
#include "Lib/Shadows.hlsl"

float3 CalcIBL(float3 viewDir, float3 n,float a){
    a = a* (1.7 - a * 0.7);
    float mip = round(a * 6);
    float3 reflectDir = reflect(-viewDir,n);
    float3 env = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectDir,mip);
    return env;
}

float3 CalcGI(){
    return 0;
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
            #pragma multi_compile_fog


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
                float4 shadowCoord:TEXCOORD4;
                float4 fogFactor:TEXCOORD5;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _PbrMask;

            float4 _MainTex_ST;
            float _Metallic,_Smoothness,_Occlusion;

            float _NormalScale;

            bool _SpecularOn;
            float _AnisoRough;

            int _PbrMode;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_COMBINE(v.vertex,v.normal,v.tangent,o/**/);
                o.shadowCoord = TransformWorldToShadowCoord(p);
                o.fogFactor.x = ComputeFogFactor(o.vertex.z);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                TANGENT_SPACE_SPLIT(i);
                float2 mainUV = i.uv;

                float4 pbrMask = tex2D(_PbrMask,mainUV);
                float metallic = pbrMask.r * _Metallic;
                float smoothness = pbrMask.g * _Smoothness;
                float occlusion = lerp(1,pbrMask.b,_Occlusion);
                float roughness = 1 - smoothness;

                float3 tn = UnpackScaleNormal(tex2D(_NormalMap,mainUV),_NormalScale);
                float3 n = normalize(TangentToWorld(i.tSpace0,i.tSpace1,i.tSpace2,tn));

                float3 l = normalize(_MainLightPosition.xyz);
                float3 v = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 h = normalize(l+v);
                
                float lh = saturate(dot(l,h));
                float nh = saturate(dot(n,h));
                float nl = saturate(dot(n,l));
                float a = roughness * roughness;
                float a2 = a * a;

                float nv = saturate(dot(n,v));

                float3 t = normalize(cross(n,float3(0,1,0)));
                float3 b = cross(t,n);
                float th = dot(t,h);
                float bh = dot(b,h);

                float shadowAtten = MainLightShadow(i.shadowCoord,worldPos);
                // return shadowAtten;
//--------- lighting
                float4 albedo = tex2D(_MainTex, mainUV);
                float radiance = _MainLightColor * nl * shadowAtten;
                
                float specTerm = 0;
                if(_SpecularOn){
                    if(_PbrMode == 0)
                        // specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                        specTerm = D_GGXNoPI(nh,a2);
                    else if(_PbrMode == 1){
                        float anisoRough = _AnisoRough + 0.5;
                        specTerm = D_GGXAnisoNoPI(th,bh,nh,anisoRough,1 - anisoRough);
                    }else if(_PbrMode == 2){
                        specTerm = D_CharlieNoPI(nh, _Smoothness);
                    }
                }

                float3 specColor = lerp(0.04,albedo,metallic);
                specColor *= specTerm;

                float3 diffColor = albedo.xyz * (1- metallic);
                float3 directColor = (diffColor + specColor) * radiance;
// return directColor.xyzx;
//------- gi
                float3 giColor = 0;
                float3 giDiff = ShadeSH9(float4(n,1)) * diffColor;

                float surfaceReduction = 1/(a2+1);
                float grazingTerm = saturate(smoothness + metallic);
                float fresnelTerm = pow(1-nv,4);
                float3 giSpec = CalcIBL(v,n,a2);
                giSpec *= surfaceReduction * lerp(specColor,grazingTerm,fresnelTerm);
                giColor = giDiff + giSpec;
                // return giSpec.xyzx;

                float4 col = 1;
                col.rgb = directColor + giColor;
//------ fog
                col.rgb = MixFog(col.xyz,i.fogFactor.x);
                return col;
            }
            ENDHLSL
        }
    }
}
