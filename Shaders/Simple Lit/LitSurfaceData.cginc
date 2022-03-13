static float arrayIndex;

half4 SampleTexture(Texture2D t, SamplerState s, float2 uv)
{
    return t.Sample(s, uv);
}

half4 SampleTexture(Texture2DArray t, SamplerState s, float2 uv)
{
    return t.Sample(s, float3(uv, arrayIndex));
}

#if defined(_TEXTURE_ARRAY)
    #define TEXARGS(tex) tex##Array
#else
    #define TEXARGS(tex) tex
#endif

void InitializeLitSurfaceData(inout SurfaceData surf, v2f i)
{
    arrayIndex = i.uv[3].z;
    float2 parallaxOffset = 0.0;
    #if defined(PARALLAX)
        float2 parallaxUV = i.uv[0].zw;
        parallaxOffset = ParallaxOffset(i.viewDirTS, parallaxUV);
    #endif

    half2 mainUV = i.uv[0].zw + parallaxOffset;
    half4 mainTexture = SampleTexture(TEXARGS(_MainTex), TEXARGS(sampler_MainTex), mainUV);

    mainTexture *= UNITY_ACCESS_INSTANCED_PROP(InstancedProps, _Color);
    
    surf.albedo = mainTexture.rgb;
    surf.alpha = mainTexture.a;


    half4 maskMap = 1.0;
    #ifdef _MASK_MAP
        maskMap = SampleTexture(TEXARGS(_MetallicGlossMap), TEXARGS(sampler_MetallicGlossMap), mainUV);
        surf.perceptualRoughness = 1.0 - (RemapMinMax(maskMap.a, _GlossinessMin, _Glossiness));
        surf.metallic = RemapMinMax(maskMap.r, _MetallicMin, _Metallic);
        surf.occlusion = lerp(1.0, maskMap.g, _Occlusion);
    #else
        surf.perceptualRoughness = 1.0 - _Glossiness;
        surf.metallic = _Metallic;
        surf.occlusion = 1.0;
    #endif

    

    half4 normalMap = float4(0.5, 0.5, 1.0, 1.0);
    #ifdef _NORMAL_MAP
        normalMap = SampleTexture(TEXARGS(_BumpMap), TEXARGS(sampler_BumpMap), mainUV);
        surf.tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);
    #endif


    #if defined(_DETAILALBEDO_MAP) || defined(_DETAILNORMAL_MAP)

        float2 detailUV = i.uv[_DetailMapUV].xy;
        float2 detailDepth = ParallaxOffsetUV(_DetailDepth, i.viewDirTS);
        detailUV = (detailUV * _DetailAlbedoMap_ST.xy) + _DetailAlbedoMap_ST.zw + parallaxOffset + detailDepth;
        float4 detailMap = 0.5;
        float3 detailAlbedo = 0.0;
        float detailSmoothness = 0.0;
        
        #if defined(_DETAILALBEDO_MAP)
            float4 sampledDetailAlbedo = SampleTexture(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUV);
        #else
            float4 sampledDetailAlbedo = half4(1.0, 1.0, 1.0, 1.0);
        #endif

        #ifdef _DETAILMASK_MAP
            float2 detailMaskUV = (i.uv[_DetailMaskUV].xy * _DetailMask_ST.xy) + _DetailMask_ST.zw + parallaxOffset ;
            float detailMask = SampleTexture(_DetailMask, sampler_DetailMask, detailMaskUV).g;
        #else
            float detailMask = maskMap.b;
        #endif

        #if defined(_DETAILNORMAL_MAP)
            float4 detailNormalMap = SampleTexture(_DetailNormalMap, sampler_DetailNormalMap, detailUV);
            float3 detailNormal = UnpackScaleNormal(detailNormalMap, _DetailNormalScale);
            #if defined(_DETAILBLEND_LERP)
                surf.tangentNormal = lerp(surf.tangentNormal, detailNormal, detailMask);
            #else
                surf.tangentNormal = lerp(surf.tangentNormal, BlendNormals(surf.tangentNormal, detailNormal), detailMask);
            #endif
        #endif

        #ifdef _DETAILALBEDO_MAP
            #if defined(_DETAILBLEND_SCREEN)
                surf.albedo = lerp(surf.albedo, BlendMode_Screen(surf.albedo, sampledDetailAlbedo.rgb), detailMask * _DetailAlbedoScale);
                surf.perceptualRoughness = lerp(surf.perceptualRoughness, BlendMode_Screen(surf.perceptualRoughness, 1.0 - sampledDetailAlbedo.a), detailMask * _DetailSmoothnessScale);
            #elif defined(_DETAILBLEND_MULX2)
                surf.albedo = lerp(surf.albedo, BlendMode_MultiplyX2(surf.albedo, sampledDetailAlbedo.rgb), detailMask * _DetailAlbedoScale);
                surf.perceptualRoughness = lerp(surf.perceptualRoughness, BlendMode_MultiplyX2(surf.perceptualRoughness, 1.0 - sampledDetailAlbedo.a), detailMask * _DetailSmoothnessScale);
            #elif defined(_DETAILBLEND_LERP)
                surf.albedo = lerp(surf.albedo, sampledDetailAlbedo.rgb, detailMask * _DetailAlbedoScale);
                surf.perceptualRoughness = lerp(surf.perceptualRoughness, 1.0 - sampledDetailAlbedo.a, detailMask * _DetailSmoothnessScale);
            #else // default overlay
                surf.albedo = lerp(surf.albedo, BlendMode_Overlay_sRGB(surf.albedo, sampledDetailAlbedo.rgb), detailMask * _DetailAlbedoScale);
                surf.perceptualRoughness = lerp(surf.perceptualRoughness, BlendMode_Overlay(surf.perceptualRoughness, 1.0 - sampledDetailAlbedo.a), detailMask * _DetailSmoothnessScale);
            #endif
        #endif
        
    #endif

    surf.albedo.rgb = lerp(dot(surf.albedo.rgb, GRAYSCALE), surf.albedo.rgb, _AlbedoSaturation);
    
    #if defined(EMISSION)
        float3 emissionMap = 1.0;

        UNITY_BRANCH
        if (_EmissionMap_TexelSize.w > 1.0)
        {
            emissionMap = SampleTexture(_EmissionMap, sampler_EmissionMap, mainUV + ParallaxOffsetUV(_EmissionDepth, i.viewDirTS)).rgb;
        }

        emissionMap = lerp(emissionMap, emissionMap * surf.albedo.rgb, _EmissionMultBase);
    
        surf.emission = emissionMap * UNITY_ACCESS_INSTANCED_PROP(InstancedProps, _EmissionColor);
        #if defined(AUDIOLINK)
            surf.emission *= AudioLinkLerp(uint2(1, _AudioLinkEmission)).r;
        #endif

        half3 emissionPulse = sin(_Time.y * _EmissionPulseSpeed) + 1;
        surf.emission = lerp(surf.emission, surf.emission * emissionPulse, _EmissionPulseIntensity);

        #ifdef UNITY_PASS_META
            surf.emission *= _EmissionGIMultiplier;
        #endif
    #endif

    surf.tangentNormal.g *= _FlipNormal ? 1.0 : -1.0;

    surf.reflectance = _Reflectance;
}