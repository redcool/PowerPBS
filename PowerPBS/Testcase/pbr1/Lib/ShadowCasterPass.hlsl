#if !defined(SHADOW_CASTER_PASS_HLSL)
#define SHADOW_CASTER_PASS_HLSL

#include "Core/CommonUtils.hlsl"
#include "PBRInput.hlsl"
#include "URP_MainLightShadows.hlsl"


struct v2f{
    half2 uv:TEXCOORD0;
    half4 pos:SV_POSITION;
};

half3 _LightDirection;

//--------- shadow helpers
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

v2f vert(appdata_full input){
    v2f output;

    output.pos = GetShadowPositionHClip(input);
    output.uv = TRANSFORM_TEX(input.texcoord,_MainTex);
    return output;
}

half4 frag(v2f input):SV_Target{
    #if defined(_ALPHA_TEST)
    if(_AlphaTestOn){
        half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
        clip(tex.a - _Cutoff);
    }
    #endif
    return 0;
}

#endif //SHADOW_CASTER_PASS_HLSL