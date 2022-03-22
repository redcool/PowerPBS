#if !defined(POWER_PBS_DEBUG_HLSL)
#define POWER_PBS_DEBUG_HLSL

half4 ShowDebug(UnityIndirect gi,WorldData worldData,SurfaceData surfaceData,half metallic,half smoothness,half occlusion){
    if(_ShowGIDiff)
        return gi.diffuse.xyzx;
    if(_ShowGISpec)
        return gi.specular.xyzx;
    if(_ShowNormal)
        return worldData.normal.xyzx;

    if(_ShowMetallic)
        return metallic;
    if(_ShowSmoothness)
        return smoothness;
    if(_ShowOcclusion)
        return occlusion;
        
    return half4(.1,.2,.3,1);
}

#endif //POWER_PBS_DEBUG_HLSL