// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// #if defined(UNITY_SHADER_VARIABLES_INCLUDED)
//     #undef UNITY_SHADER_VARIABLES_INCLUDED
// #endif
#ifndef UNITY_SHADER_VARIABLES_INCLUDED
#define UNITY_SHADER_VARIABLES_INCLUDED

#include "../Tools/Common.hlsl"
#include "../UrpLib/URP_Input.hlsl"

#if defined (DIRECTIONAL_COOKIE) || defined (DIRECTIONAL)
#define USING_DIRECTIONAL_LIGHT
#endif

#if defined(UNITY_SINGLE_PASS_STEREO) || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
#define USING_STEREO_MATRICES
#endif

#if defined(USING_STEREO_MATRICES)
    #define glstate_matrix_projection unity_StereoMatrixP[unity_StereoEyeIndex]
    #define unity_MatrixV unity_StereoMatrixV[unity_StereoEyeIndex]
    #define unity_MatrixInvV unity_StereoMatrixInvV[unity_StereoEyeIndex]
    #define unity_MatrixVP unity_StereoMatrixVP[unity_StereoEyeIndex]

    #define unity_CameraProjection unity_StereoCameraProjection[unity_StereoEyeIndex]
    #define unity_CameraInvProjection unity_StereoCameraInvProjection[unity_StereoEyeIndex]
    #define unity_WorldToCamera unity_StereoWorldToCamera[unity_StereoEyeIndex]
    #define unity_CameraToWorld unity_StereoCameraToWorld[unity_StereoEyeIndex]
    #define _WorldSpaceCameraPos unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex]
#endif

#define UNITY_MATRIX_P glstate_matrix_projection
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_I_V unity_MatrixInvV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_M unity_ObjectToWorld

#define UNITY_LIGHTMODEL_AMBIENT (glstate_lightmodel_ambient * 2)

// ----------------------------------------------------------------------------


CBUFFER_START(UnityPerCamera)
    // Time (t = time since current level load) values from Unity
    half4 _Time; // (t/20, t, t*2, t*3)
    half4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)
    half4 _CosTime; // cos(t/8), cos(t/4), cos(t/2), cos(t)
    half4 unity_DeltaTime; // dt, 1/dt, smoothdt, 1/smoothdt

#if !defined(USING_STEREO_MATRICES)
    half3 _WorldSpaceCameraPos;
#endif

    // x = 1 or -1 (-1 if projection is flipped)
    // y = near plane
    // z = far plane
    // w = 1/far plane
    half4 _ProjectionParams;

    // x = width
    // y = height
    // z = 1 + 1.0/width
    // w = 1 + 1.0/height
    half4 _ScreenParams;

    // Values used to linearize the Z buffer (http://www.humus.name/temp/Linearize%20depth.txt)
    // x = 1-far/near
    // y = far/near
    // z = x/far
    // w = y/far
    // or in case of a reversed depth buffer (UNITY_REVERSED_Z is 1)
    // x = -1+far/near
    // y = 1
    // z = x/far
    // w = 1/far
    half4 _ZBufferParams;

    // x = orthographic camera's width
    // y = orthographic camera's height
    // z = unused
    // w = 1.0 if camera is ortho, 0.0 if perspective
    half4 unity_OrthoParams;
#if defined(STEREO_CUBEMAP_RENDER_ON)
    //x-component is the half stereo separation value, which a positive for right eye and negative for left eye. The y,z,w components are unused.
    half4 unity_HalfStereoSeparation;
#endif
CBUFFER_END


CBUFFER_START(UnityPerCameraRare)
    half4 unity_CameraWorldClipPlanes[6];

#if !defined(USING_STEREO_MATRICES)
    // Projection matrices of the camera. Note that this might be different from projection matrix
    // that is set right now, e.g. while rendering shadows the matrices below are still the projection
    // of original camera.
    half4x4 unity_CameraProjection;
    half4x4 unity_CameraInvProjection;
    half4x4 unity_WorldToCamera;
    half4x4 unity_CameraToWorld;
#endif
CBUFFER_END



// ----------------------------------------------------------------------------

CBUFFER_START(UnityLighting)
    half4 _LightPositionRange; // xyz = pos, w = 1/range
    half4 _LightProjectionParams; // for point light projection: x = zfar / (znear - zfar), y = (znear * zfar) / (znear - zfar), z=shadow bias, w=shadow scale bias

    half4 unity_4LightPosX0;
    half4 unity_4LightPosY0;
    half4 unity_4LightPosZ0;
    half4 unity_4LightAtten0;

    half4 unity_LightColor[8];


    half4 unity_LightPosition[8]; // view-space vertex light positions (position,1), or (-direction,0) for directional lights.
    // x = cos(spotAngle/2) or -1 for non-spot
    // y = 1/cos(spotAngle/4) or 1 for non-spot
    // z = quadratic attenuation
    // w = range*range
    half4 unity_LightAtten[8];
    half4 unity_SpotDirection[8]; // view-space spot light directions, or (0,0,1,0) for non-spot



    // part of Light because it can be used outside of shadow distance
    half4 unity_OcclusionMaskSelector;
    // half4 unity_ProbesOcclusion;
CBUFFER_END

CBUFFER_START(UnityLightingOld)
    half3 unity_LightColor0, unity_LightColor1, unity_LightColor2, unity_LightColor3; // keeping those only for any existing shaders; remove in 4.0
CBUFFER_END


// ----------------------------------------------------------------------------

CBUFFER_START(UnityShadows)
    half4 unity_ShadowSplitSpheres[4];
    half4 unity_ShadowSplitSqRadii;
    // half4 unity_LightShadowBias;
    half4 _LightSplitsNear;
    half4 _LightSplitsFar;
    half4x4 unity_WorldToShadow[4];
    half4 _LightShadowData;
    half4 unity_ShadowFadeCenterAndType;
CBUFFER_END

// ----------------------------------------------------------------------------
 // UnityInput.hlsl
CBUFFER_START(UnityPerDraw)
    half4x4 unity_ObjectToWorld;
    half4x4 unity_WorldToObject;
    half4 unity_LODFade; // x is the fade value ranging within [0,1]. y is x quantized into 16 levels
    half4 unity_WorldTransformParams; // w is usually 1.0, or -1.0 for odd-negative scale transforms
    half4 unity_RenderingLayer;
   
    half4 unity_LightData;
    half4 unity_LightIndices[2];
        
    half4 unity_ProbesOcclusion;

    half4  unity_SpecCube0_HDR;

    half4  unity_SpecCube1_HDR;

    half4 unity_LightmapST;
    half4 unity_LightmapIndex;
    half4 unity_DynamicLightmapST;

    // SH lighting environment
    half4 unity_SHAr;
    half4 unity_SHAg;
    half4 unity_SHAb;
    half4 unity_SHBr;
    half4 unity_SHBg;
    half4 unity_SHBb;
    half4 unity_SHC;

    #if UNITY_LIGHT_PROBE_PROXY_VOLUME
        // x = Disabled(0)/Enabled(1)
        // y = Computation are done in global space(0) or local space(1)
        // z = Texel size on U texture coordinate
        half4 unity_ProbeVolumeParams;

        half4x4 unity_ProbeVolumeWorldToObject;
        half3 unity_ProbeVolumeSizeInv;
        half3 unity_ProbeVolumeMin;
    #endif   

CBUFFER_END

#if defined(USING_STEREO_MATRICES)
GLOBAL_CBUFFER_START(UnityStereoGlobals)
    half4x4 unity_StereoMatrixP[2];
    half4x4 unity_StereoMatrixV[2];
    half4x4 unity_StereoMatrixInvV[2];
    half4x4 unity_StereoMatrixVP[2];

    half4x4 unity_StereoCameraProjection[2];
    half4x4 unity_StereoCameraInvProjection[2];
    half4x4 unity_StereoWorldToCamera[2];
    half4x4 unity_StereoCameraToWorld[2];

    half3 unity_StereoWorldSpaceCameraPos[2];
    half4 unity_StereoScaleOffset[2];
GLOBAL_CBUFFER_END
#endif

#if defined(USING_STEREO_MATRICES) && defined(UNITY_STEREO_MULTIVIEW_ENABLED)
GLOBAL_CBUFFER_START(UnityStereoEyeIndices)
    half4 unity_StereoEyeIndices[2];
GLOBAL_CBUFFER_END
#endif

#if defined(UNITY_STEREO_MULTIVIEW_ENABLED) && defined(SHADER_STAGE_VERTEX)
    #define unity_StereoEyeIndex UNITY_VIEWID
    UNITY_DECLARE_MULTIVIEW(2);
#elif defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
    static uint unity_StereoEyeIndex;
#elif defined(UNITY_SINGLE_PASS_STEREO)
    GLOBAL_CBUFFER_START(UnityStereoEyeIndex)
        int unity_StereoEyeIndex;
    GLOBAL_CBUFFER_END
#endif

CBUFFER_START(UnityPerDrawRare)
    half4x4 glstate_matrix_transpose_modelview0;
CBUFFER_END


// ----------------------------------------------------------------------------

CBUFFER_START(UnityPerFrame)

    half4 glstate_lightmodel_ambient;
    half4 unity_AmbientSky;
    half4 unity_AmbientEquator;
    half4 unity_AmbientGround;
    half4 unity_IndirectSpecColor;

#if !defined(USING_STEREO_MATRICES)
    half4x4 glstate_matrix_projection;
    half4x4 unity_MatrixV;
    half4x4 unity_MatrixInvV;
    half4x4 unity_MatrixVP;
    int unity_StereoEyeIndex;
#endif

    half4 unity_ShadowColor;
CBUFFER_END


// ----------------------------------------------------------------------------

CBUFFER_START(UnityFog)
    half4 unity_FogColor;
    // x = density / sqrt(ln(2)), useful for Exp2 mode
    // y = density / ln(2), useful for Exp mode
    // z = -1/(end-start), useful for Linear mode
    // w = end/(end-start), useful for Linear mode
    half4 unity_FogParams;
CBUFFER_END


// ----------------------------------------------------------------------------
// Lightmaps

/*

// Main lightmap
UNITY_DECLARE_TEX2D_HALF(unity_Lightmap);
// Directional lightmap (always used with unity_Lightmap, so can share sampler)
UNITY_DECLARE_TEX2D_NOSAMPLER_HALF(unity_LightmapInd);
// Shadowmasks
UNITY_DECLARE_TEX2D(unity_ShadowMask);

// Dynamic GI lightmap
UNITY_DECLARE_TEX2D(unity_DynamicLightmap);
UNITY_DECLARE_TEX2D_NOSAMPLER(unity_DynamicDirectionality);
UNITY_DECLARE_TEX2D_NOSAMPLER(unity_DynamicNormal);

CBUFFER_START(UnityLightmaps)
    half4 unity_LightmapST;
    half4 unity_DynamicLightmapST;
CBUFFER_END
*/

// ----------------------------------------------------------------------------
// Reflection Probes

TEXTURECUBE(unity_SpecCube0); SAMPLER(samplerunity_SpecCube0);
// UNITY_DECLARE_TEXCUBE_NOSAMPLER(unity_SpecCube1);

CBUFFER_START(UnityReflectionProbes)
    half4 unity_SpecCube0_BoxMax;
    half4 unity_SpecCube0_BoxMin;
    half4 unity_SpecCube0_ProbePosition;


    half4 unity_SpecCube1_BoxMax;
    half4 unity_SpecCube1_BoxMin;
    half4 unity_SpecCube1_ProbePosition;

CBUFFER_END


// ----------------------------------------------------------------------------
// Light Probe Proxy Volume

// UNITY_LIGHT_PROBE_PROXY_VOLUME is used as a shader keyword coming from tier settings and may be also disabled with nolppv pragma.
// We need to convert it to 0/1 and doing a second check for safety.
#ifdef UNITY_LIGHT_PROBE_PROXY_VOLUME
    #undef UNITY_LIGHT_PROBE_PROXY_VOLUME
    // Requires quite modern graphics support (3D half textures with filtering)
    // Note: Keep this in synch with the list from LightProbeProxyVolume::HasHardwareSupport && SurfaceCompiler::IsLPPVAvailableForAnyTargetPlatform
    #if !defined(UNITY_NO_LPPV) && (defined (SHADER_API_D3D11) || defined (SHADER_API_D3D12) || defined (SHADER_API_GLCORE) || defined (SHADER_API_PSSL) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_SWITCH) || defined(SHADER_API_GLES3))
        #define UNITY_LIGHT_PROBE_PROXY_VOLUME 1
    #else
        #define UNITY_LIGHT_PROBE_PROXY_VOLUME 0
    #endif
#else
    #define UNITY_LIGHT_PROBE_PROXY_VOLUME 0
#endif
     
#if UNITY_LIGHT_PROBE_PROXY_VOLUME
    // UNITY_DECLARE_TEX3D_half(unity_ProbeVolumeSH);

    // CBUFFER_START(UnityProbeVolume)

    // CBUFFER_END
#endif

static half4x4 unity_MatrixMVP = mul(unity_MatrixVP, unity_ObjectToWorld);
static half4x4 unity_MatrixMV = mul(unity_MatrixV, unity_ObjectToWorld);
static half4x4 unity_MatrixTMV = transpose(unity_MatrixMV);
static half4x4 unity_MatrixITMV = transpose(mul(unity_WorldToObject, unity_MatrixInvV));
// make them macros so that they can be redefined in UnityInstancing.cginc
#define UNITY_MATRIX_MVP    unity_MatrixMVP
#define UNITY_MATRIX_MV     unity_MatrixMV
#define UNITY_MATRIX_T_MV   unity_MatrixTMV
#define UNITY_MATRIX_IT_MV  unity_MatrixITMV

// ----------------------------------------------------------------------------
//  Deprecated

// There used to be half function-like texture matrices, defined as UNITY_MATRIX_TEXTUREn. These are gone now; and are just defined to identity.
#define UNITY_MATRIX_TEXTURE0 half4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
#define UNITY_MATRIX_TEXTURE1 half4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
#define UNITY_MATRIX_TEXTURE2 half4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
#define UNITY_MATRIX_TEXTURE3 half4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

#endif
