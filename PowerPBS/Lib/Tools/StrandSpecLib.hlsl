#if !defined(STRAND_SPEC_LIB_HLSL)
#define STRAND_SPEC_LIB_HLSL
    float StrandSpecular ( float3 T, float3 V, float3 L, float exponent)
    {
        float3 H = normalize(L + V);
        float dotTH = dot(T, H);
        float sinTH = sqrt(1 - dotTH * dotTH);
        float dirAtten = smoothstep(-1, 0, dotTH);
        return dirAtten * pow(sinTH, exponent);
    }
    
    float3 ShiftTangent ( float3 T, float3 N, float shift)
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

    float3 StrandSpecularColor(StrandSpecularData data){
        float3 tb = lerp(data.tangent,data.binormal,data.tbMask);
        float3 t = ShiftTangent(data.binormal,data.normal,data.shift);
        float spec = StrandSpecular(t,data.viewDir,data.lightDir,data.specPower);
        spec = smoothstep(0.5,0.9,spec);
        return spec;
    }

    // float3 CalcStrandSpec(float3 tangent,float3 normal,float3 binormal,float3 lightDir,float3 viewDir,float tangentShift,float tbMask,float2 specMask){
//     StrandSpecularData data = (StrandSpecularData)0;
//     data.tangent = tangent;
//     data.normal = normal;
//     data.binormal = binormal;
//     data.lightDir = lightDir;
//     data.viewDir = viewDir;
//     data.shift = tangentShift + _Shift1;
//     data.specPower = _SpecPower1 * 128;
//     data.tbMask = tbMask;

//     float3 spec1 = StrandSpecularColor(data);

//     data.specPower = _SpecPower2 * 128;
//     data.shift = tangentShift + _Shift2;
//     float3 spec2 = StrandSpecularColor(data);
//     float3 specColor = spec1 * _SpecIntensity1 * _SpecColor1 * specMask.x + spec2 * _SpecIntensity2 * _SpecColor2 * specMask.y;
//     return specColor;
// }

/**
    strandSpec main
*/
// float3 CalcHairSpecColor(float3 tangent,float3 normal,float3 binormal,float3 lightDir,float3 viewDir,float3 shift_specMask_tbMask){
//     float shift = shift_specMask_tbMask.x;
//     float specMask = shift_specMask_tbMask.y;
//     float tbMask = shift_specMask_tbMask.z;
//     return CalcStrandSpec(tangent,normal,binormal,lightDir,viewDir,shift,tbMask,float2(1,specMask));
// }
#endif // STRAND_SPEC_LIB_HLSL