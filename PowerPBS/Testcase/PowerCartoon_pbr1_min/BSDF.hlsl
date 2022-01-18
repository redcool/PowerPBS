#if !defined(BSDF_HLSL)

half3 PreScattering(sampler2D scatterMap,half3 normal,half3 lightDir,half3 lightColor,half nl,half4 mainTex,half3 worldPos,half curveScale,half scatterIntensity,bool preScatterMaskUseMainTexA){
    half wnl = dot(normal,(lightDir)) * 0.5 + 0.5;
    half atten = 1-wnl;//smoothstep(0.,0.5,nl);
    half3 scattering = tex2D(scatterMap,half2(wnl,curveScale ));
    half scatterMask = lerp(1,mainTex.w,preScatterMaskUseMainTexA);
    return scattering * lightColor * mainTex.xyz * atten * scatterIntensity * scatterMask;
}

#endif // BSDF_HLSL