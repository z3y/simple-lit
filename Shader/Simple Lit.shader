﻿Shader "Simple Lit"
{
    Properties
    {

        [KeywordEnum(Opaque, Cutout, Fade, Transparent)] _Mode ("Rendering Mode", Int) = 0
        [HideInInspector] [ToggleOff(_MODE_OPAQUE)] _KeywordOffOpaque ("", Float) = 1

        _Cutoff ("Alpha Cuttoff", Range(0, 1)) = 0.5

        _MainTex ("Base Map", 2D) = "white" {}
            _AlbedoSaturation ("Saturation", Range(0,2)) = 1
            _Color ("Base Color", Color) = (1,1,1,1)

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _GlossinessMin ("Smoothness Min", Range(0,1)) = 0
        [Gamma] _Metallic ("Metallic", Range(0,1)) = 0
        _MetallicMin ("Metallic Min", Range(0,1)) = 0
        _Occlusion ("Occlusion", Range(0,1)) = 0

        _MetallicGlossMap ("Packed Mask:Metallic (R) | Occlusion (G) | Detail Mask (B) | Smoothness (A)", 2D) = "white" {}

        _IsPackingMetallicGlossMap ("", Float) = 0
        _MetallicMap ("Metallic Map", 2D) = "black" {}
        [Enum(R, 0, G, 1, B, 2, A, 3)]  _MetallicMapChannel ("", Int) = 0
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        [Enum(R, 0, G, 1, B, 2, A, 3)]  _OcclusionMapChannel ("", Int) = 0
        _DetailMaskMap ("Detail Mask", 2D) = "white" {}
        [Enum(R, 0, G, 1, B, 2, A, 3)]  _DetailMaskMapChannel ("", Int) = 0
        _SmoothnessMap ("Smoothness Map", 2D) = "white" {}
        [Enum(R, 0, G, 1, B, 2, A, 3)]  _SmoothnessMapChannel ("", Int) = 0
        [ToggleUI] _SmoothnessMapInvert ("Use Roughness", Float) = 0


        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
            _BumpScale ("Bump Scale", Float) = 1

        [ToggleOff(SPECULAR_HIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights", Float) = 1
        [ToggleOff(REFLECTIONS_OFF)] _GlossyReflections("Reflections", Float) = 1
            _SpecularOcclusion ("Fresnel Occlusion", Range(0,1)) = 0

        [Toggle(GEOMETRIC_SPECULAR_AA)] _GSAA ("Geometric Specular AA", Int) = 0
            [PowerSlider(2)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
            [PowerSlider(2)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1

        [Toggle(EMISSION)] _EnableEmission ("Emission", Int) = 0
            _EmissionMap ("Emission Map", 2D) = "white" {}
            [ToggleUI] _EmissionMultBase ("Multiply Base", Int) = 0
            [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)


        _DetailAlbedoMap ("Detail Albedo:Albedo (RGB) | Smoothness (A)", 2D) = "linearGrey" {}
        [Normal] _DetailNormalMap ("Detail Normal", 2D) = "bump" {}
            [Enum(UV0, 0, UV1, 1)]  _DetailMapUV ("Detail UV", Int) = 0
            _DetailAlbedoScale ("Albedo Scale", Range(0.0, 2.0)) = 1
            _DetailNormalScale ("Normal Scale", Float) = 1
            _DetailSmoothnessScale ("Smoothness Scale", Range(0.0, 2.0)) = 0

        [Toggle(PARALLAX)] _EnableParallax ("Parallax", Int) = 0
            _Parallax ("Height Scale", Range (0, 0.2)) = 0.02
            _ParallaxMap ("Height Map", 2D) = "white" {}
            [IntRange] _ParallaxSteps ("Parallax Steps", Range(1,50)) = 25
            _ParallaxOffset ("Parallax Offset", Range(-1, 1)) = 0


        [Toggle(NONLINEAR_LIGHTPROBESH)] _NonLinearLightProbeSH ("Non-linear Light Probe SH", Int) = 0
        [Toggle(BAKEDSPECULAR)] _BakedSpecular ("Baked Specular ", Int) = 0

        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Blend Op Alpha", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
        [Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage", Int) = 0


        [KeywordEnum(None, SH, RNM)] Bakery ("Bakery Mode", Int) = 0
        [HideInInspector] [ToggleOff(BAKERY_NONE)] _KeywordOffBakery ("", Float) = 1
            _RNM0("RNM0", 2D) = "black" {}
            _RNM1("RNM1", 2D) = "black" {}
            _RNM2("RNM2", 2D) = "black" {}
        

    }
    SubShader
    {
        CGINCLUDE
        #pragma target 4.5
        #pragma vertex vert
        #pragma fragment frag
        #pragma fragmentoption ARB_precision_hint_fastest

        #pragma skip_variants VERTEXLIGHT_ON
        #pragma skip_variants LOD_FADE_CROSSFADE
        ENDCG

        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "FORWARDBASE"
            Tags { "LightMode"="ForwardBase" }
            ZWrite [_ZWrite]
            Cull [_Cull]
            ZTest [_ZTest]
            AlphaToMask [_AlphaToMask]
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend [_SrcBlend] [_DstBlend]

            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            

            #define BICUBIC_LIGHTMAP
            #pragma shader_feature_local_fragment _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT
            #pragma shader_feature_local _ BAKERY_SH BAKERY_RNM
            #pragma shader_feature_local_fragment SPECULAR_HIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment REFLECTIONS_OFF
            #pragma shader_feature_local_fragment EMISSION
            #pragma shader_feature_local_fragment NONLINEAR_LIGHTPROBESH
            #pragma shader_feature_local_fragment BAKEDSPECULAR
            #pragma shader_feature_local_fragment GEOMETRIC_SPECULAR_AA
            #pragma shader_feature_local PARALLAX

            #pragma shader_feature_local_fragment _MASK_MAP
            #pragma shader_feature_local_fragment _NORMAL_MAP
            #pragma shader_feature_local_fragment _DETAILALBEDO_MAP
            #pragma shader_feature_local_fragment _DETAILNORMAL_MAP

            #include "PassCGI.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARDADD"
            Tags { "LightMode"="ForwardAdd" }
            Fog { Color (0,0,0,0) }
            ZWrite Off
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend One One
            Cull [_Cull]
            ZTest [_ZTest]
            AlphaToMask [_AlphaToMask]

            CGPROGRAM
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma shader_feature_local_fragment _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT
            #pragma shader_feature_local_fragment SPECULAR_HIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment NONLINEAR_LIGHTPROBESH
            #pragma shader_feature_local_fragment GEOMETRIC_SPECULAR_AA
            #pragma shader_feature_local PARALLAX

            #pragma shader_feature_local_fragment _MASK_MAP
            #pragma shader_feature_local_fragment _NORMAL_MAP
            #pragma shader_feature_local_fragment _DETAILALBEDO_MAP
            #pragma shader_feature_local_fragment _DETAILNORMAL_MAP
            
            #include "PassCGI.cginc"

            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags { "LightMode"="ShadowCaster" }
            AlphaToMask Off
            ZWrite On
            Cull [_Cull]
            ZTest LEqual

            CGPROGRAM
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #pragma shader_feature_local_fragment _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT

            #include "PassCGI.cginc"
            ENDCG
        }

        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }
            Cull Off

            CGPROGRAM
            #pragma shader_feature EDITOR_VISUALIZATION

            #pragma shader_feature_local_fragment _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT
            #pragma shader_feature_local_fragment EMISSION            

            #include "PassCGI.cginc"
            ENDCG
        }
    }
    CustomEditor "z3y.Shaders.SimpleLit.ShaderEditor"
}
