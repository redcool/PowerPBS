# PowerPBS
power shader for render advanced detail character,
4 lightmode :
    standard used for common,
    aniso used for silk,hair,
    cloth used for clothes,
    strandSpec used for hair too.

has more detail maps and alpha control
no lightmap
clear coat
specular map flow and metallic flow
3 scatter:
    preintegral sss for mobile skin
    ssss used for advanced skin(need add DiffuseProfile to scene's gameobject)
    fastSSS used for porcelain


warning: 
urp need add PowerURPLitFeatures to urp's ForwardRendererData



Reference Git
https://github.com/redcool/PowerUtilities.git
https://github.com/redcool/PowerShaderLib.git

put them into same folder.

-----------------------------------------------
(v2.0.2)
New Features:
    1 sheen layer, can simulate skin, satin
Update:
    _SpecularOff to shader_feature

(v2.0.3)
New Features:
    1 add _BlendVertexNormalOn, in main page
    2 add _VertexScaleOn,in vertex page
