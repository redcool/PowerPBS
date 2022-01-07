/**
    MainLight Shadow
*/
#if !defined(MAIN_LIGHT_SHADOW_HLSL)
#define MAIN_LIGHT_SHADOW_HLSL

TEXTURE2D_SHADOW(_MainLightShadowmapTexture);SAMPLER_CMP(sampler_MainLightShadowmapTexture);

#if defined(SHADER_API_MOBILE)
    static const int SOFT_SHADOW_COUNT = 2;
    static const half SOFT_SHADOW_WEIGHTS[] = {0.2,0.4,0.4};
#else
    static const int SOFT_SHADOW_COUNT = 4;
    static const half SOFT_SHADOW_WEIGHTS[] = {0.2,0.25,0.25,0.15,0.15};
#endif 

#ifndef SHADER_API_GLES3
CBUFFER_START(MainLightShadows)
#endif
    #define MAX_SHADOW_CASCADES 4
    half4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
    half4      _CascadeShadowSplitSpheres0;
    half4      _CascadeShadowSplitSpheres1;
    half4      _CascadeShadowSplitSpheres2;
    half4      _CascadeShadowSplitSpheres3;
    half4      _CascadeShadowSplitSphereRadii;
    half4       _MainLightShadowOffset0;
    half4       _MainLightShadowOffset1;
    half4       _MainLightShadowOffset2;
    half4       _MainLightShadowOffset3;
    half4       _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise, z: oneOverFadeDist, w: minusStartFade)
    half4      _MainLightShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
// CBUFFER_END
#ifndef SHADER_API_GLES3
CBUFFER_END
#endif

#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0

half ComputeCascadeIndex(half3 positionWS)
{
    half3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
    half3 fromCenter1 = positionWS - _CascadeShadowSplitSpheres1.xyz;
    half3 fromCenter2 = positionWS - _CascadeShadowSplitSpheres2.xyz;
    half3 fromCenter3 = positionWS - _CascadeShadowSplitSpheres3.xyz;
    half4 distances2 = half4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

    half4 weights = half4(distances2 < _CascadeShadowSplitSphereRadii);
    weights.yzw = saturate(weights.yzw - weights.xyz);

    return 4 - dot(weights, half4(4, 3, 2, 1));
}

half4 TransformWorldToShadowCoord(half3 positionWS)
{
#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
    half cascadeIndex = ComputeCascadeIndex(positionWS);
#else
    half cascadeIndex = 0;
#endif

    half4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], half4(positionWS, 1.0));

    return half4(shadowCoord.xyz, cascadeIndex);
}

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

    half SampleShadowmap(TEXTURE2D_SHADOW_PARAM(shadowMap,sampler_ShadowMap),half4 shadowCoord,half shadowSoftScale){
        half shadow = SAMPLE_TEXTURE2D_SHADOW(shadowMap,sampler_ShadowMap, shadowCoord.xyz);

        // return shadow;
        shadow *= SOFT_SHADOW_WEIGHTS[0];

        half2 psize = _MainLightShadowmapSize.xy * shadowSoftScale;
        const half2 uvs[] = { half2(-psize.x,0),half2(0,psize.y),half2(psize.x,0),half2(0,-psize.y) };

        half2 offset = 0;
        for(int x=0;x< SOFT_SHADOW_COUNT;x++){
            offset = uvs[x] ;
            shadow +=SAMPLE_TEXTURE2D_SHADOW(shadowMap,sampler_ShadowMap, half3(shadowCoord.xy + offset,shadowCoord.z)) * SOFT_SHADOW_WEIGHTS[x+1];
        }
        
        return shadow;
    }

    bool MainLightEnabled(){
        return _MainLightShadowOn;
    }

    half CalcShadow (half4 shadowCoord,half3 worldPos)
    {
        half shadow = 1;
        if(MainLightEnabled()){
            //shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture, shadowCoord.xyz);
            shadow = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture),shadowCoord,_MainLightShadowSoftScale);
            shadow = lerp(1,shadow,_MainLightShadowParams.x); // shadow intensity
            shadow = BEYOND_SHADOW_FAR(shadowCoord) ? 1 : shadow; // shadow range

            half shadowFade = GetShadowFade(worldPos); 
            shadowFade = shadowCoord.w == 4 ? 1.0 : shadowFade;
            
            shadow = lerp(shadow,1,shadowFade);
        }
        return shadow;
    }

#endif //MAIN_LIGHT_SHADOW_HLSL