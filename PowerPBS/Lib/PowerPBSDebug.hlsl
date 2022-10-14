#if !defined(POWER_PBS_DEBUG_HLSL)
#define POWER_PBS_DEBUG_HLSL

float4 ShowDebug(UnityIndirect gi,WorldData worldData,SurfaceData surfaceData,float metallic,float smoothness,float occlusion){
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
    if(_ShowSpecular)
        return surfaceData.specColor.xyzx;
    if(_ShowDiffuse)
        return surfaceData.diffColor.xyzx;
    return float4(.1,.2,.3,1);
}

#endif //POWER_PBS_DEBUG_HLSL