#if !defined(POWER_PBS_DEBUG_HLSL)
#define POWER_PBS_DEBUG_HLSL

float4 ShowDebug(UnityIndirect gi,WorldData worldData,SurfaceData surfaceData,float metallic,float smoothness,float occlusion){
   branch_if(_ShowGIDiff)
        return gi.diffuse.xyzx;
   branch_if(_ShowGISpec)
        return gi.specular.xyzx;
   branch_if(_ShowNormal)
        return worldData.normal.xyzx;

   branch_if(_ShowMetallic)
        return metallic;
   branch_if(_ShowSmoothness)
        return smoothness;
   branch_if(_ShowOcclusion)
        return occlusion;
   branch_if(_ShowSpecular)
        return surfaceData.specColor.xyzx;
   branch_if(_ShowDiffuse)
        return surfaceData.diffColor.xyzx;
    return float4(.1,.2,.3,1);
}

#endif //POWER_PBS_DEBUG_HLSL