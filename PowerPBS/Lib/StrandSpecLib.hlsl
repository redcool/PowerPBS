#if !defined(STRAND_SPEC_LIB_HLSL)
#define STRAND_SPEC_LIB_HLSL
    inline half StrandSpecular ( half3 T, half3 V, half3 L, half exponent)
    {
        half3 H = normalize(L + V);
        half dotTH = dot(T, H);
        half sinTH = sqrt(1 - dotTH * dotTH);
        half dirAtten = smoothstep(-1, 0, dotTH);
        return dirAtten * pow(sinTH, exponent);
    }
    
    inline half3 ShiftTangent ( half3 T, half3 N, half shift)
    {
        return normalize(T + shift * N);
    }
    
    struct StrandSpecularData{
        float3 tangent;
        float3 normal;
        float3 binormal;
        float tbMask;/*tangent or binormal mask*/
        float shift; 
        float3 lightDir;
        float3 viewDir;
        float specPower;
    };

    inline float3 StrandSpecularColor(StrandSpecularData data){
        float3 tb = lerp(data.tangent,data.binormal,data.tbMask);
        float3 t = ShiftTangent(tb,data.normal,data.shift);
        float spec = StrandSpecular(t,data.viewDir,data.lightDir,data.specPower);
        spec = smoothstep(0.5,0.9,spec);
        return spec;
    }
#endif // STRAND_SPEC_LIB_HLSL