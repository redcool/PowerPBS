#if !defined(SIMPLE_PBS_HAIR_HLSL)
#define SIMPLE_PBS_HAIR_HLSL
#include "StrandSpecLib.hlsl"
#include "PowerPBSInput.hlsl"

/**
    Move StrandSpec parameters to PowerPBSInput.hlsl 's UnityPerMaterial
*/



float3 CalcStrandSpec(float3 tangent,float3 normal,float3 binormal,float3 lightDir,float3 viewDir,float tangentShift,float tbMask,float2 specMask){
    StrandSpecularData data = (StrandSpecularData)0;
    data.tangent = tangent;
    data.normal = normal;
    data.binormal = binormal;
    data.lightDir = lightDir;
    data.viewDir = viewDir;
    data.shift = tangentShift + _Shift1;
    data.specPower = _SpecPower1 * 128;
    data.tbMask = tbMask;

    float spec1 = StrandSpecularColor(data);

    data.specPower = _SpecPower2 * 128;
    data.shift = tangentShift + _Shift2;
    float spec2 = StrandSpecularColor(data);
    float3 specColor = spec1 * _SpecIntensity1 * _SpecColor1 * specMask.x + spec2 * _SpecIntensity2 * _SpecColor2 * specMask.y;
    return specColor;
}

/**
    strandSpec main
*/
float3 CalcHairSpecColor(float3 tangent,float3 normal,float3 binormal,float3 lightDir,float3 viewDir,float3 shift_specMask_tbMask){
    float shift = shift_specMask_tbMask.x;
    float specMask = shift_specMask_tbMask.y;
    float tbMask = shift_specMask_tbMask.z;
    return CalcStrandSpec(tangent,normal,binormal,lightDir,viewDir,shift,tbMask,float2(1,specMask));
}

#endif //SIMPLE_PBS_HAIR_HLSL