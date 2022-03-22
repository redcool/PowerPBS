#if !defined(POWER_PBS_DEBUG_HLSL)
#define POWER_PBS_DEBUG_HLSL

half4 ShowGI(UnityIndirect gi){
    if(_ShowGIDiff)
        return gi.diffuse.xyzx;
    if(_ShowGISpec)
        return gi.specular.xyzx;
    return half4(.1,.2,.3,1);
}

#endif //POWER_PBS_DEBUG_HLSL