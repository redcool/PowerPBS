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
        half3 tangent;
        half3 normal;
        half3 binormal;
        half tbMask;/*tangent or binormal mask*/
        half shift; 
        half3 lightDir;
        half3 viewDir;
        half specPower;
    };

    inline half3 StrandSpecularColor(StrandSpecularData data){
        half3 tb = lerp(data.tangent,data.binormal,data.tbMask);
        half3 t = ShiftTangent(tb,data.normal,data.shift);
        half spec = StrandSpecular(t,data.viewDir,data.lightDir,data.specPower);
        spec = smoothstep(0.5,0.9,spec);
        return spec;
    }
#endif // STRAND_SPEC_LIB_HLSL