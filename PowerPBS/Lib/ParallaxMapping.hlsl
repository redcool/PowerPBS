#if !defined(POM_HLSL)
#define POM_HLSL

#undef TANGENT_SPACE_ROTATION
#define TANGENT_SPACE_ROTATION(input)\
    float3 b = normalize(cross(input.normal,input.tangent.xyz)) * input.tangent.w;\
    float3x3 rotation = float3x3(input.tangent.xyz,b,input.normal)

float2 ParallaxMapOffset(float heightScale,float3 viewTS,float height){
    return (height-0.5)* heightScale * normalize(viewTS).xy * 0.5;
}

float2 ParallaxOcclusionOffset(float heightScale,float3 viewTS,float sampleRatio,float2 uv,sampler2D heightMap,int minCount,int maxCount){
    float parallaxLimit = -length(viewTS.xy)/viewTS.z;
    parallaxLimit *= heightScale;

    float2 offsetDir = normalize(viewTS.xy);
    float2 maxOffset = offsetDir * parallaxLimit;

    int numSamples = (int)lerp(minCount,maxCount,saturate(sampleRatio));
    float stepSize = 1.0/numSamples;

    float2 dx = ddx(uv);
    float2 dy = ddy(uv);

    float2 curOffset = 0;
    float2 lastOffset = 0;

    float curRayHeight = 1;
    float curHeight=1,lastHeight = 1;

    int curSample = 0;
    while(curSample < numSamples){
        curHeight = tex2Dgrad(heightMap,uv + curOffset,dx,dy).x;
        if( curHeight > curRayHeight){
            float delta1 = curHeight - curRayHeight;
            float delta2 = (curRayHeight + stepSize) - lastHeight;

            float ratio = delta1 /(delta1 + delta2);

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