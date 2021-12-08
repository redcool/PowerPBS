/**
    MainLight Shadow
    shadows 
    URP keyword URP_SHADOW required
    drp keyword SHADOW_SCREEN required
*/
#if !defined(POWER_PBS_SHADOW_HLSL)
#define POWER_PBS_SHADOW_HLSL

// open keywords
// #if defined(URP_SHADOW)
//     #undef SHADOWS_SCREEN
// #else    
//     #define SHADOWS_SCREEN
// #endif

// #include "UnityLib/AutoLight.hlsl"
//--------- urp shadow handles
// CBUFFER_START(MainLightShadows)
    #define MAX_SHADOW_CASCADES 4
    half4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
    half4       _MainLightShadowOffset0;
    half4       _MainLightShadowOffset1;
    half4       _MainLightShadowOffset2;
    half4       _MainLightShadowOffset3;
    half4       _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise, z: oneOverFadeDist, w: minusStartFade)
// CBUFFER_END

#undef TRANSFER_SHADOW
#define TRANSFER_SHADOW(a) a._ShadowCoord = mul( _MainLightWorldToShadow[0], mul( unity_ObjectToWorld, v.vertex ) );

#undef SHADOW_COORDS
#define SHADOW_COORDS(idx1) half4 _ShadowCoord : TEXCOORD##idx1;

// #if defined (URP_SHADOW)

    half4 _ShadowBias; // x: depth bias, y: normal bias
    half _MainLightShadowOn; //send  from PowerUrpLitFeature



    half3 ApplyShadowBias(half3 positionWS, half3 normalWS, half3 lightDirection)
    {
        half invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
        half scale = invNdotL * (_ShadowBias.y + _CustomShadowBias.y);

        // normal bias is negative since we want to apply an inset normal offset
        positionWS = lightDirection * (_ShadowBias.xxx + _CustomShadowBias.xxx) + positionWS;
        positionWS = normalWS * scale.xxx + positionWS;
        return positionWS;
    }
    
    half GetShadowFade(half3 positionWS)
    {
        half3 camToPixel = positionWS - _WorldSpaceCameraPos;
        half distanceCamToPixel2 = dot(camToPixel, camToPixel);

        half fade = saturate(distanceCamToPixel2 * _MainLightShadowParams.z + _MainLightShadowParams.w);
        return fade * fade;
    }

    inline half CalcShadow (half4 shadowCoord,half3 worldPos)
    {
        half shadow = 1;
        // #if defined(SHADOWS_NATIVE)
            if(_MainLightShadowOn){
                shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture, shadowCoord.xyz);
                    //half shadow = _MainLightShadowmapTexture.SampleCmpLevelZero(sampler_MainLightShadowmapTexture,shadowCoord.xy,shadowCoord.z);
                shadow = lerp(1,shadow,_MainLightShadowParams.x);
                half shadowFade = GetShadowFade(worldPos);
                shadow = lerp(shadow,1,shadowFade);
            }
        // #endif
        return shadow;
    }


// #endif

// #if !defined(URP_SHADOW)
//     // drp shadows , call AutoLight.cginc' SHADOW_ATTENUATION
//     #define URP_SHADOW_ATTENUATION(a,worldPos) SHADOW_ATTENUATION(a)
// #else
    //urp shadows
    #define URP_SHADOW_ATTENUATION(a,worldPos) CalcShadow(a._ShadowCoord,worldPos)
// #endif

#endif //POWER_PBS_SHADOW_HLSL