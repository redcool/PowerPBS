#if !defined(BLUR_HLSL)
#define BLUR_HLSL
#include "Common.hlsl"

const static float gaussWeights[4]={0.00038771,0.01330373,0.11098164,0.22508352};

float3 GaussBlur(TEXTURE2D_PARAM(tex,sampler_tex),float2 uv,float2 offset,bool samplerCenter){
    float4 c = 0;
   branch_if(samplerCenter){
        c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv) * gaussWeights[3];
    }
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv + offset) * gaussWeights[2];
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv - offset) * gaussWeights[2];

    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv + offset * 2) * gaussWeights[1];
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv - offset * 2) * gaussWeights[1];

    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv + offset * 3) * gaussWeights[0];
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv - offset * 3) * gaussWeights[0];
    return c.xyz;
}


#if defined(SHADER_API_D3D11)
    #define KERNEL_SIZE 25
#else
    #define KERNEL_SIZE 18
#endif

#define DistanceToProjectionWindow 5.671281819617709             //1.0 / tan(0.5 * radians(20));
#define DPTimes300 1701.384545885313                             //DistanceToProjectionWindow * 300
float4 _Kernel[KERNEL_SIZE];
static const float4 _LocalKernel[25] = {
    {1,0.4354057,1,0},{0,0.001171291,0,-3},{0,0.004015044,0,-2.520833},{0,0.00601844,0,-2.083333},{0,0.008431426,0,-1.6875},{0,0.01135324,0,-1.333333},{0,0.0154557,0,-1.020833},{0,0.02155918,0,-0.75},{0,0.03171116,0,-0.5208333},{0,0.04933598,0,-0.3333333},{0,0.05936943,0,-0.1875},{0,0.04844738,0,-0.08333334},{7.519899E-16,0.02542887,7.519899E-16,-0.02083333},{7.519899E-16,0.02542887,7.519899E-16,0.02083333},{0,0.04844738,0,0.08333334},{0,0.05936943,0,0.1875},{0,0.04933598,0,0.3333333},{0,0.03171116,0,0.5208333},{0,0.02155918,0,0.75},{0,0.0154557,0,1.020833},{0,0.01135324,0,1.333333},{0,0.008431426,0,1.6875},{0,0.00601844,0,2.083333},{0,0.004015044,0,2.520833},{0,0.001171291,0,3},
};

float4 CalcKernel(int id){
    return _Kernel[id];
    // return _LocalKernel[id];
}

float3 DiffuseProfile(float3 mainColor,TEXTURE2D_PARAM(tex,sampler_tex),float2 uv,float2 offset,float sssMask,float baseScale=0.2){
    float BlurLength = DistanceToProjectionWindow;
    float2 uvOffset = BlurLength*offset;

    // base color
    float3 blurColor = mainColor.xyz * CalcKernel(0).xyz* baseScale;

    UNITY_LOOP
    for(int i = 0;i < KERNEL_SIZE ; i++){
        float4 k = CalcKernel(i);
        float2 sssuv = uv + k.w * uvOffset;
        float3 sssColor = SAMPLE_TEXTURE2D(tex,sampler_tex,sssuv).xyz;
        // sssColor = lerp(mainColor,sssColor,saturate(sssMask));

        blurColor += k.xyz * sssColor;
    }
    return lerp(mainColor.xyz,blurColor,sssMask);
}

#endif //BLUR_HLSL