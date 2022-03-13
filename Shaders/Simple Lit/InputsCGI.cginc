Texture2D _MainTex; SamplerState sampler_MainTex;
Texture2D _MetallicGlossMap; SamplerState sampler_MetallicGlossMap;
Texture2D _BumpMap; SamplerState sampler_BumpMap;

Texture2D _DetailMask; SamplerState sampler_DetailMask;
Texture2D _DetailNormalMap; SamplerState sampler_DetailNormalMap;
Texture2D _DetailAlbedoMap; SamplerState sampler_DetailAlbedoMap;

Texture2D _EmissionMap; SamplerState sampler_EmissionMap;

Texture2DArray _MainTexArray; SamplerState sampler_MainTexArray;
Texture2DArray _BumpMapArray; SamplerState sampler_BumpMapArray;
Texture2DArray _MetallicGlossMapArray; SamplerState sampler_MetallicGlossMapArray;

half _Glossiness;
half _GlossinessMin;
half _Metallic;
half _MetallicMin;
half _Occlusion;

half _BumpScale;
half _FlipNormal;
half _Reflectance;

half4 _DetailAlbedoMap_ST;
uint _DetailMaskUV;
half4 _DetailMask_ST;
uint _DetailMapUV;
half _DetailDepth;
half _DetailAlbedoScale;
half _DetailNormalScale;
half _DetailSmoothnessScale;

half _AlbedoSaturation;
half _SpecularOcclusion;
half _Cutoff;

half _Texture;
half _AudioLinkEmission;
half _DetailAlbedoAlpha;

half4 _EmissionMap_TexelSize;
half _EmissionMultBase;
half _EmissionDepth;
half _EmissionPulseIntensity;
half _EmissionPulseSpeed;
half _EmissionGIMultiplier;


UNITY_INSTANCING_BUFFER_START(InstancedProps)
    UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
    UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
    UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
    UNITY_DEFINE_INSTANCED_PROP(half3, _EmissionColor)
UNITY_INSTANCING_BUFFER_END(InstancedProps)