#if !defined(SIMPLE_PBS_HAIR_HLSL)
#define SIMPLE_PBS_HAIR_HLSL
#include "Tools/StrandSpecLib.hlsl"
#include "PowerPBSInput.hlsl"

/**
    Move StrandSpec parameters to PowerPBSInput.hlsl 's UnityPerMaterial
*/



half3 CalcStrandSpec(half3 tangent,half3 normal,half3 binormal,half3 lightDir,half3 viewDir,half tangentShift,half tbMask,half2 specMask){
    StrandSpecularData data = (StrandSpecularData)0;
    data.tangent = tangent;
    data.normal = normal;
    data.binormal = binormal;
    data.lightDir = lightDir;
    data.viewDir = viewDir;
    data.shift = tangentShift + _Shift1;
    data.specPower = _SpecPower1 * 128;
    data.tbMask = tbMask;

    half spec1 = StrandSpecularColor(data);

    data.specPower = _SpecPower2 * 128;
    data.shift = tangentShift + _Shift2;
    half spec2 = StrandSpecularColor(data);
    half3 specColor = spec1 * _SpecIntensity1 * _SpecColor1 * specMask.x + spec2 * _SpecIntensity2 * _SpecColor2 * specMask.y;
    return specColor;
}

/**
    strandSpec main
*/
half3 CalcHairSpecColor(half3 tangent,half3 normal,half3 binormal,half3 lightDir,half3 viewDir,half3 shift_specMask_tbMask){
    half shift = shift_specMask_tbMask.x;
    half specMask = shift_specMask_tbMask.y;
    half tbMask = shift_specMask_tbMask.z;
    return CalcStrandSpec(tangent,normal,binormal,lightDir,viewDir,shift,tbMask,half2(1,specMask));
}

#endif //SIMPLE_PBS_HAIR_HLSL