/**
    like UnityCG.cginc
*/

#if !defined(COMMON_UTILS_HLSL)
#define COMMON_UTILS_HLSL
#include "Common.hlsl"

#include "UnityLib/UnityShaderUtilities.hlsl"
#include "UnityLib/UnityInstancing.hlsl"

// ----------------------- UnityCG.cginc 
#if !defined(UNITY_CG_INCLUDED)

#ifdef UNITY_COLORSPACE_GAMMA
#define unity_ColorSpaceGrey half4(0.5, 0.5, 0.5, 0.5)
#define unity_ColorSpaceDouble half4(2.0, 2.0, 2.0, 2.0)
#define unity_ColorSpaceDielectricSpec half4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301)
#define unity_ColorSpaceLuminance half4(0.22, 0.707, 0.071, 0.0) // Legacy: alpha is set to 0.0 to specify gamma mode
#else // Linear values
#define unity_ColorSpaceGrey half4(0.214041144, 0.214041144, 0.214041144, 0.5)
#define unity_ColorSpaceDouble half4(4.59479380, 4.59479380, 4.59479380, 2.0)
#define unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
#define unity_ColorSpaceLuminance half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode
#endif

#define _WorldSpaceLightPos0 _MainLightPosition // redefine 

struct appdata_base {
    half4 vertex : POSITION;
    half3 normal : NORMAL;
    half4 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct appdata_tan {
    half4 vertex : POSITION;
    half4 tangent : TANGENT;
    half3 normal : NORMAL;
    half4 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct appdata_full {
    half4 vertex : POSITION;
    half4 tangent : TANGENT;
    half3 normal : NORMAL;
    half4 texcoord : TEXCOORD0;
    half4 texcoord1 : TEXCOORD1;
    half4 texcoord2 : TEXCOORD2;
    half4 texcoord3 : TEXCOORD3;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


// Tranforms position from world to homogenous space
inline half4 UnityWorldToClipPos( in half3 pos )
{
    return mul(UNITY_MATRIX_VP, half4(pos, 1.0));
}

// Tranforms position from view to homogenous space
inline half4 UnityViewToClipPos( in half3 pos )
{
    return mul(UNITY_MATRIX_P, half4(pos, 1.0));
}

// Tranforms position from object to camera space
inline half3 UnityObjectToViewPos( in half3 pos )
{
    return mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, half4(pos, 1.0))).xyz;
}
inline half3 UnityObjectToViewPos(half4 pos) // overload for half4; avoids "implicit truncation" warning for existing shaders
{
    return UnityObjectToViewPos(pos.xyz);
}

// Tranforms position from world to camera space
inline half3 UnityWorldToViewPos( in half3 pos )
{
    return mul(UNITY_MATRIX_V, half4(pos, 1.0)).xyz;
}

// Transforms direction from object to world space
inline half3 UnityObjectToWorldDir( in half3 dir )
{
    return normalize(mul((half3x3)unity_ObjectToWorld, dir));
}

// Transforms direction from world to object space
inline half3 UnityWorldToObjectDir( in half3 dir )
{
    return normalize(mul((half3x3)unity_WorldToObject, dir));
}

// Transforms normal from object to world space
inline half3 UnityObjectToWorldNormal( in half3 norm )
{
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return UnityObjectToWorldDir(norm);
#else
    // mul(IT_M, norm) => mul(norm, I_M) => {dot(norm, I_M.col0), dot(norm, I_M.col1), dot(norm, I_M.col2)}
    return normalize(mul(norm, (half3x3)unity_WorldToObject));
#endif
}

// Computes world space light direction, from world space position
inline half3 UnityWorldSpaceLightDir( in half3 worldPos )
{
    #ifndef USING_LIGHT_MULTI_COMPILE
        return _WorldSpaceLightPos0.xyz - worldPos * _WorldSpaceLightPos0.w;
    #else
        #ifndef USING_DIRECTIONAL_LIGHT
        return _WorldSpaceLightPos0.xyz - worldPos;
        #else
        return _WorldSpaceLightPos0.xyz;
        #endif
    #endif
}

// Computes world space light direction, from object space position
// *Legacy* Please use UnityWorldSpaceLightDir instead
inline half3 WorldSpaceLightDir( in half4 localPos )
{
    half3 worldPos = mul(unity_ObjectToWorld, localPos).xyz;
    return UnityWorldSpaceLightDir(worldPos);
}

// Computes object space light direction
inline half3 ObjSpaceLightDir( in half4 v )
{
    half3 objSpaceLightPos = mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz;
    #ifndef USING_LIGHT_MULTI_COMPILE
        return objSpaceLightPos.xyz - v.xyz * _WorldSpaceLightPos0.w;
    #else
        #ifndef USING_DIRECTIONAL_LIGHT
        return objSpaceLightPos.xyz - v.xyz;
        #else
        return objSpaceLightPos.xyz;
        #endif
    #endif
}

// Computes world space view direction, from object space position
inline half3 UnityWorldSpaceViewDir( in half3 worldPos )
{
    return _WorldSpaceCameraPos.xyz - worldPos;
}

// Computes world space view direction, from object space position
// *Legacy* Please use UnityWorldSpaceViewDir instead
inline half3 WorldSpaceViewDir( in half4 localPos )
{
    half3 worldPos = mul(unity_ObjectToWorld, localPos).xyz;
    return UnityWorldSpaceViewDir(worldPos);
}

// Computes object space view direction
inline half3 ObjSpaceViewDir( in half4 v )
{
    half3 objSpaceCameraPos = mul(unity_WorldToObject, half4(_WorldSpaceCameraPos.xyz, 1)).xyz;
    return objSpaceCameraPos - v.xyz;
}

// normal should be normalized, w=1.0
half3 SHEvalLinearL0L1 (half4 normal)
{
    half3 x;

    // Linear (L1) + constant (L0) polynomial terms
    x.r = dot(unity_SHAr,normal);
    x.g = dot(unity_SHAg,normal);
    x.b = dot(unity_SHAb,normal);

    return x;
}

// normal should be normalized, w=1.0
half3 SHEvalLinearL2 (half4 normal)
{
    half3 x1, x2;
    // 4 of the quadratic (L2) polynomials
    half4 vB = normal.xyzz * normal.yzzx;
    x1.r = dot(unity_SHBr,vB);
    x1.g = dot(unity_SHBg,vB);
    x1.b = dot(unity_SHBb,vB);

    // Final (5th) quadratic (L2) polynomial
    half vC = normal.x*normal.x - normal.y*normal.y;
    x2 = unity_SHC.rgb * vC;

    return x1 + x2;
}

// normal should be normalized, w=1.0
// output in active color space
half3 ShadeSH9 (half4 normal)
{
    // Linear + constant polynomial terms
    half3 res = SHEvalLinearL0L1 (normal);

    // Quadratic polynomials
    res += SHEvalLinearL2 (normal);

#   ifdef UNITY_COLORSPACE_GAMMA
        res = LinearToGammaSpace (res);
#   endif

    return res;
}

// Transforms 2D UV by scale/bias property
#define TRANSFORM_TEX(tex,name) (tex.xy * name##_ST.xy + name##_ST.zw)



// Converts color to luminance (grayscale)
inline half Luminance(half3 rgb)
{
    return dot(rgb, unity_ColorSpaceLuminance.rgb);
}

// Decodes HDR textures
// handles dLDR, RGBM formats
inline half3 DecodeHDR (half4 data, half4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;

    // If Linear mode is not supported we can skip exponent part
    #if defined(UNITY_COLORSPACE_GAMMA)
        return (decodeInstructions.x * alpha) * data.rgb;
    #else
    #   if defined(UNITY_USE_NATIVE_HDR)
            return decodeInstructions.x * data.rgb; // Multiplier for future HDRI relative to absolute conversion.
    #   else
            return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * data.rgb;
    #   endif
    #endif
}

half4 ComputeScreenPos(half4 positionCS)
{
    half4 o = positionCS * 0.5f;
    o.xy = half2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = positionCS.zw;
    return o;
}

//------------ fog

#if UNITY_REVERSED_Z
    #if SHADER_API_OPENGL || SHADER_API_GLES || SHADER_API_GLES3
        //GL with reversed z => z clip range is [near, -far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(-(coord), 0)
    #else
        //D3d with reversed Z => z clip range is [near, 0] -> remapping to [0, far]
        //max is required to protect ourselves from near plane not being correct/meaningfull in case of oblique matrices.
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(((1.0-(coord)/_ProjectionParams.y)*_ProjectionParams.z),0)
    #endif
#elif UNITY_UV_STARTS_AT_TOP
    //D3d without reversed z => z clip range is [0, far] -> nothing to do
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#else
    //Opengl => z clip range is [-near, far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#endif


#endif  //! UNITY_CG_INCLUDED

inline half Pow2(half a){return a*a;}

inline half Pow4(half a){
    half a2 = a*a;
    return a2*a2;
}

inline half Pow5(half a){
    half a2 = a*a;
    return a2*a2*a;
}


half SafeDiv(half numer, half denom)
{
    return (numer != denom) ? numer / denom : 1;
}
half3 SafeNormalize(half3 inVec)
{
    half3 dp3 = max(FLT_MIN, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}

half3 UnpackScaleNormalRGorAG(half4 packednormal, half bumpScale)
{
    #if defined(UNITY_NO_DXT5nm)
        half3 normal = packednormal.xyz * 2 - 1;
        #if (SHADER_TARGET >= 30)
            // SM2.0: instruction count limitation
            // SM2.0: normal scaler is not supported
            normal.xy *= bumpScale;
        #endif
        return normal;
    #elif defined(UNITY_ASTC_NORMALMAP_ENCODING)
        half3 normal;
        normal.xy = (packednormal.wy * 2 - 1);
        normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
        normal.xy *= bumpScale;
        return normal;
    #else
        // This do the trick
        packednormal.x *= packednormal.w;

        half3 normal;
        normal.xy = (packednormal.xy * 2 - 1);
        #if (SHADER_TARGET >= 30)
            // SM2.0: instruction count limitation
            // SM2.0: normal scaler is not supported
            normal.xy *= bumpScale;
        #endif
        normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
        return normal;
    #endif
}

half3 UnpackScaleNormal(half4 packednormal, half bumpScale)
{
    return UnpackScaleNormalRGorAG(packednormal, bumpScale);
}

inline half OneMinusReflectivityFromMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}
inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}
#endif //COMMON_UTILS_HLSL