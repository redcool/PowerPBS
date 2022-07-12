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
        half3 t = ShiftTangent(data.binormal,data.normal,data.shift);
        half spec = StrandSpecular(t,data.viewDir,data.lightDir,data.specPower);
        spec = smoothstep(0.5,0.9,spec);
        return spec;
    }

    // half3 CalcStrandSpec(half3 tangent,half3 normal,half3 binormal,half3 lightDir,half3 viewDir,half tangentShift,half tbMask,half2 specMask){
//     StrandSpecularData data = (StrandSpecularData)0;
//     data.tangent = tangent;
//     data.normal = normal;
//     data.binormal = binormal;
//     data.lightDir = lightDir;
//     data.viewDir = viewDir;
//     data.shift = tangentShift + _Shift1;
//     data.specPower = _SpecPower1 * 128;
//     data.tbMask = tbMask;

//     half3 spec1 = StrandSpecularColor(data);

//     data.specPower = _SpecPower2 * 128;
//     data.shift = tangentShift + _Shift2;
//     half3 spec2 = StrandSpecularColor(data);
//     half3 specColor = spec1 * _SpecIntensity1 * _SpecColor1 * specMask.x + spec2 * _SpecIntensity2 * _SpecColor2 * specMask.y;
//     return specColor;
// }

/**
    strandSpec main
*/
// half3 CalcHairSpecColor(half3 tangent,half3 normal,half3 binormal,half3 lightDir,half3 viewDir,half3 shift_specMask_tbMask){
//     half shift = shift_specMask_tbMask.x;
//     half specMask = shift_specMask_tbMask.y;
//     half tbMask = shift_specMask_tbMask.z;
//     return CalcStrandSpec(tangent,normal,binormal,lightDir,viewDir,shift,tbMask,half2(1,specMask));
// }
#endif // STRAND_SPEC_LIB_HLSL