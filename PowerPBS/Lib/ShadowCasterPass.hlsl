#if !defined(SHADOW_CASTER_PASS_HLSL)
#define SHADOW_CASTER_PASS_HLSL

#include "Tools/CommonUtils.hlsl"
#include "PowerPBSInput.hlsl"
#include "UrpLib/URP_MainLightShadows.hlsl"


struct v2f{
    float2 uv:TEXCOORD0;
    float4 pos:SV_POSITION;
};

float3 _LightDirection;

//--------- shadow helpers
float4 GetShadowPositionHClip(appdata_full input){
    float3 worldPos = mul(unity_ObjectToWorld,input.vertex).xyz;
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

    // #if defined(URP_SHADOW)
        output.pos = GetShadowPositionHClip(input);
    // #else 
    //     output.pos = UnityClipSpaceShadowCasterPos(input.vertex, input.normal);
    //     output.pos = UnityApplyLinearShadowBias(output.pos);
    // #endif
    output.uv = TRANSFORM_TEX(input.texcoord,_MainTex);
    return output;
}

float4 frag(v2f input):SV_Target{
    #if defined(_ALPHA_TEST)
    if(_AlphaTestOn){
        float4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
        clip(tex.a - _Cutoff);
    }
    #endif
    return 0;
}

#endif //SHADOW_CASTER_PASS_HLSL