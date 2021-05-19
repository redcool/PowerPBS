#if !defined(POWERPBS_SHADOW_CASTER_PASS_CGINC)
#define POWERPBS_SHADOW_CASTER_PASS_CGINC

//#define URP_SHADOW , define this in shader file
#include "UnityCG.cginc"
#include "PowerPBSUrpShadows.cginc"

float3 _LightDirection;

struct v2f{
    float2 uv:TEXCOORD0;
    float4 pos:SV_POSITION;
};
sampler2D _MainTex;
float4 _MainTex_ST;

//--------- shadow helpers
float4 GetShadowPositionHClip(appdata_full input){
    float3 worldPos = mul(unity_ObjectToWorld,input.vertex);
    float3 worldNormal = UnityObjectToWorldNormal(input.normal);
    float4 positionCS = UnityWorldToClipPos(ApplyShadowBias(worldPos,worldNormal,_LightDirection));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}


v2f vert(appdata_full input){
    v2f output;
    #if defined(URP_SHADOW)
        output.pos = GetShadowPositionHClip(input);
    #else 
        output.pos = UnityClipSpaceShadowCasterPos(input.vertex, input.normal);
        output.pos = UnityApplyLinearShadowBias(output.pos );
    #endif
    // output.pos = mul(unity_ObjectToWorld,input.vertex);
    output.uv = TRANSFORM_TEX(input.texcoord,_MainTex);
    return output;
}

float4 frag(v2f input):SV_Target{
    float4 tex = tex2D(_MainTex,input.uv);
    clip(tex.a - 0.5);
    return 0;
}

#endif //POWERPBS_SHADOW_CASTER_PASS_CGINC