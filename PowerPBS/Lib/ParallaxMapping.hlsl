#if !defined(POM_HLSL)
#define POM_HLSL

#undef TANGENT_SPACE_ROTATION
#define TANGENT_SPACE_ROTATION(input)\
    half3 b = normalize(cross(input.normal,input.tangent.xyz)) * input.tangent.w;\
    half3x3 rotation = half3x3(input.tangent.xyz,b,input.normal)

half2 ParallaxMapOffset(half heightScale,half3 viewTS,half height){
    return (height-0.5)* heightScale * normalize(viewTS).xy * 0.5;
}

half2 ParallaxOcclusionOffset(half heightScale,half3 viewTS,half sampleRatio,half2 uv,sampler2D heightMap,int minCount,int maxCount){
    half parallaxLimit = -length(viewTS.xy)/viewTS.z;
    parallaxLimit *= heightScale;

    half2 offsetDir = normalize(viewTS.xy);
    half2 maxOffset = offsetDir * parallaxLimit;

    int numSamples = (int)lerp(minCount,maxCount,saturate(sampleRatio));
    half stepSize = 1.0/numSamples;

    half2 dx = ddx(uv);
    half2 dy = ddy(uv);

    half2 curOffset = 0;
    half2 lastOffset = 0;

    half curRayHeight = 1;
    half curHeight=1,lastHeight = 1;

    int curSample = 0;
    while(curSample < numSamples){
        curHeight = tex2Dgrad(heightMap,uv + curOffset,dx,dy).x;
        if( curHeight > curRayHeight){
            half delta1 = curHeight - curRayHeight;
            half delta2 = (curRayHeight + stepSize) - lastHeight;

            half ratio = delta1 /(delta1 + delta2);

            curOffset = lerp(curOffset,lastOffset,ratio);
            curSample = numSamples + 1;
        }else{
            curSample ++;
            curRayHeight -= stepSize;

            lastOffset = curOffset;
            curOffset += stepSize * maxOffset;

            lastHeight = curHeight;
        }
    }
    return curOffset;
}
#endif //POM_HLSL