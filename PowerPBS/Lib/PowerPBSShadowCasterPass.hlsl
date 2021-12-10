#if !defined(POWERPBS_SHADOW_CASTER_PASS_HLSL)
#define POWERPBS_SHADOW_CASTER_PASS_HLSL

#include "CommonUtils.hlsl"
#include "PowerPBSInput.hlsl"
#include "PowerPBSUrpShadows.hlsl"

half3 _LightDirection;

struct v2f{
    half2 uv:TEXCOORD0;
    half4 pos:SV_POSITION;
};

//--------- shadow helpers
// #if defined(URP_SHADOW)
half4 GetShadowPositionHClip(appdata_full input){
    half3 worldPos = mul(unity_ObjectToWorld,input.vertex);
    half3 worldNormal = UnityObjectToWorldNormal(input.normal);
    half4 positionCS = UnityWorldToClipPos(ApplyShadowBias(worldPos,worldNormal,_LightDirection));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}
// #endif

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

half4 frag(v2f input):SV_Target{
    if(_AlphaTestOn){
        half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
        clip(tex.a - _Cutoff);
    }
    return 0;
}

#endif //POWERPBS_SHADOW_CASTER_PASS_HLSL