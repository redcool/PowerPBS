// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef UNITY_SHADER_UTILITIES_INCLUDED
#define UNITY_SHADER_UTILITIES_INCLUDED

// This file is always included in all unity shaders.

#include "UnityShaderVariables.hlsl"

half3 ODSOffset(half3 worldPos, half ipd)
{
    //based on google's omni-directional stereo rendering thread
    const half EPSILON = 2.4414e-4;
    half3 worldUp = half3(0.0, 1.0, 0.0);
    half3 camOffset = worldPos.xyz - _WorldSpaceCameraPos.xyz;
    half4 direction = half4(camOffset.xyz, dot(camOffset.xyz, camOffset.xyz));
    direction.w = max(EPSILON, direction.w);
    direction *= rsqrt(direction.w);

    half3 tangent = cross(direction.xyz, worldUp.xyz);
    if (dot(tangent, tangent) < EPSILON)
        return half3(0, 0, 0);
    tangent = normalize(tangent);

    half directionMinusIPD = max(EPSILON, direction.w*direction.w - ipd*ipd);
    half a = ipd * ipd / direction.w;
    half b = ipd / direction.w * sqrt(directionMinusIPD);
    half3 offset = -a * direction.xyz + b * tangent;
    return offset;
}

inline half4 UnityObjectToClipPosODS(half3 inPos)
{
    half4 clipPos;
    half3 posWorld = mul(unity_ObjectToWorld, half4(inPos, 1.0)).xyz;
#if defined(STEREO_CUBEMAP_RENDER_ON)
    half3 offset = ODSOffset(posWorld, unity_HalfStereoSeparation.x);
    clipPos = mul(UNITY_MATRIX_VP, half4(posWorld + offset, 1.0));
#else
    clipPos = mul(UNITY_MATRIX_VP, half4(posWorld, 1.0));
#endif
    return clipPos;
}

// Tranforms position from object to homogenous space
inline half4 UnityObjectToClipPos(in half3 pos)
{
#if defined(STEREO_CUBEMAP_RENDER_ON)
    return UnityObjectToClipPosODS(pos);
#else
    // More efficient than computing M*VP matrix product
    return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, half4(pos, 1.0)));
#endif
}
inline half4 UnityObjectToClipPos(half4 pos) // overload for half4; avoids "implicit truncation" warning for existing shaders
{
    return UnityObjectToClipPos(pos.xyz);
}

#endif
