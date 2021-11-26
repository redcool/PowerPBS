Shader "Lit/pbr1_"
{
    /*
    lighting(pbr,charlie,aniso)
    shadow(main light)
    fog
    srp batched 

    instanced
    detail()
    alpha

    */
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _NormalMap("_NormalMap",2d)="bump"{}
        _NormalScale("_NormalScale",float) = 1

        _PbrMask("_PbrMask",2d)="white"{}

        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
        _Occlusion("_Occlusion",range(0,1)) = 0

        [Toggle]_SpecularOn("_SpecularOn",int) = 1

        // [Enum(PBR,0,Aniso,1,Charlie,2)]_PbrMode("_PbrMode",int) = 0
        [KeywordEnum(None,PBR,Aniso,Charlie)]_PbrMode("_PbrMode",int) = 0

        [Header(Aniso)]
        [Toggle]_CalcTangent("_CalcTangent",int) = 0
        _AnisoRough("_AnisoRough",range(-0.5,0.5)) = 0
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
            #pragma target 3.0
            // #pragma multi_compile_fog
            #pragma multi_compile _PBRMODE_NONE _PBRMODE_PBR _PBRMODE_ANISO _PBRMODE_CHARLIE
            #include "Lib/PBRForwardPass.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                TANGENT_SPACE_DECLARE(1,2,3);
                float4 shadowCoord:TEXCOORD4;
                float4 fogFactor:TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_COMBINE(v.vertex,v.normal,v.tangent,o/**/);
                o.shadowCoord = TransformWorldToShadowCoord(p);
                o.fogFactor.x = ComputeFogFactor(o.vertex.z);


                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                TANGENT_SPACE_SPLIT(i);
                float2 mainUV = i.uv;

                float4 pbrMask = tex2D(_PbrMask,mainUV);
                float metallic = pbrMask.r * _Metallic;
                float smoothness = pbrMask.g * _Smoothness;
                float occlusion = lerp(1,pbrMask.b,_Occlusion);
                float roughness = 1 - smoothness;

                float3 tn = UnpackScaleNormal(tex2D(_NormalMap,mainUV),_NormalScale);
                float3 n = normalize(TangentToWorld(i.tSpace0,i.tSpace1,i.tSpace2,tn));

                float3 l = (_MainLightPosition.xyz);
                float3 v = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 h = normalize(l+v);
                
                float lh = saturate(dot(l,h));
                float nh = saturate(dot(n,h));
                float nl = saturate(dot(n,l));
                float a = roughness * roughness;
                float a2 = a * a;

                float nv = saturate(dot(n,v));
// return v.xyzx;


                float shadowAtten = MainLightShadow(i.shadowCoord,worldPos);
                // return shadowAtten;
//--------- lighting
                float4 albedo = tex2D(_MainTex, mainUV);
                float radiance = _MainLightColor * nl * shadowAtten;
                
                float specTerm = 0;

                // if(_SpecularOn){
                    // if(_PbrMode == 0){
                    #if defined(_PBRMODE_NONE)

                    #elif defined(_PBRMODE_PBR)
                        // specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                        specTerm = D_GGXNoPI(nh,a2);
                    // }else if(_PbrMode == 1){
                    #elif defined(_PBRMODE_ANISO)
                        float3 t = tangent;//(cross(n,float3(0,1,0)));
                        float3 b = binormal;//cross(t,n);
                        if(_CalcTangent){
                            t = cross(n,float3(0,1,0));
                            b = cross(t,n);
                        }
                        float th = dot(t,h);
                        float bh = dot(b,h);
                        float anisoRough = roughness;//_AnisoRough + 0.5;
                        specTerm = D_GGXAnisoNoPI(th,bh,nh,anisoRough,1 - anisoRough);
                    #elif defined(_PBRMODE_CHARLIE)
                    // }else if(_PbrMode == 2){
                        specTerm = D_CharlieNoPI(nh, roughness);
                    // }
                    #endif
                // }

                float3 specColor = lerp(0.04,albedo,metallic);
                
                float3 diffColor = albedo.xyz * (1- metallic);
                float3 directColor = (diffColor + specColor * specTerm) * radiance;
// return directColor.xyzx;
//------- gi
                float3 giColor = 0;
                float3 giDiff = ShadeSH9(float4(n,1)) * diffColor;

                float surfaceReduction = 1/(a2+1);
                float grazingTerm = saturate(smoothness + metallic);
                float fresnelTerm = Pow4(1-nv);
                float3 giSpec = CalcIBL(v,n,a2);
                // return  lerp(specColor,grazingTerm,fresnelTerm).xyzx;
                giSpec *= surfaceReduction * lerp(specColor,grazingTerm,fresnelTerm);
                giColor = giDiff + giSpec;
// return giColor.xyzx;

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
