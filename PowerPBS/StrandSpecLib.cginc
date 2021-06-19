#if !defined(STRAND_SPEC_LIB_CGINC)
#define STRAND_SPEC_LIB_CGINC
    inline fixed StrandSpecular ( fixed3 T, fixed3 V, fixed3 L, fixed exponent)
    {
        fixed3 H = normalize(L + V);
        fixed dotTH = dot(T, H);
        fixed sinTH = sqrt(1 - dotTH * dotTH);
        fixed dirAtten = smoothstep(-1, 0, dotTH);
        return dirAtten * pow(sinTH, exponent);
    }
    
    inline fixed3 ShiftTangent ( fixed3 T, fixed3 N, fixed shift)
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
#endif // STRAND_SPEC_LIB_CGINC