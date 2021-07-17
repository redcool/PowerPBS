#if !defined(POWER_PBS_DATA_CGINC)
#define POWER_PBS_DATA_CGINC

#include "PowerPBSInput.cginc"


struct PBSData{
    float3 tangent;
    float3 binormal;
    float clothMask;
    float3 hairSpecColor;
    bool isAnisoLayer2On;
    //
    float nl;
};

inline PBSData InitPBSData(float3 tangent,float3 binormal,float clothMask){
    PBSData data = (PBSData)0;
    data.tangent = tangent;
    data.binormal = binormal;
    data.clothMask = 1;
    data.isAnisoLayer2On = _AnisoLayer2On;

    return data;
}    
#endif //POWER_PBS_DATA_CGINC