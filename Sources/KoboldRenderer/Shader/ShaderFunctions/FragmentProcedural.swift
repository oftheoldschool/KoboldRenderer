class FragmentShaderFunctionTemplateProcedural: FragmentShaderFunctionTemplate {
    override class var functionName: String { "proceduralFragment" }
    override class var inputLayout: String { "FullFragmentInput" }

    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "ColorPlusDepth"),
            .instancedColor: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "ColorPlusDepth"),

            .colorAlpha: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaFragmentOutput",
                attachmentLayout: "ColorPlusRevealagePlusDepth"),
            .instancedColorAlpha: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaFragmentOutput",
                attachmentLayout: "ColorPlusRevealagePlusDepth"),

            .colorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "BloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusDepth"),
            .instancedColorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "BloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusDepth"),

            .colorAlphaPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaBloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusRevealagePlusDepth"),
            .instancedColorAlphaPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaBloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusRevealagePlusDepth"),

            .gbuffer: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusMaterials",
                outputLayout: "GBufferFragmentOutput",
                attachmentLayout: "GBuffer"),
            .instancedGBuffer: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusMaterials",
                outputLayout: "GBufferFragmentOutput",
                attachmentLayout: "GBuffer"),
        ]
    }

    override class var textureLayout: String {
        "CascadedShadowMap"
    }

    override class var materialLayout: String {
        "None"
    }

    override class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
    constant MaterialUniforms & material = materials[uniformsObject.materialId];
    constant MaterialUniforms & globalMaterial = materials[uniformsShared.globalMaterialId];
    
    FractalNoiseMetalParameters noiseParameters {
        .lacunarity = material.noiseLacunarity,
        .gain = material.noisePersistence,
        .startingAmplitude = 2,
        .startingFrequency = material.noiseScale,
        .octaves = material.noiseOctaves,
        .warpIterations = 1,
        .warpScale = 1,
        .coordinateScale = 25,
        .noiseType = FractalNoiseMetalType::openSimplex2,
        .noiseTypeParameters = {
            .openSimplex2Parameters = {
                .seed = 1337,
                .noise3Variant = OpenSimplex2MetalNoise3Variant::xz,
            },
        },
    };
    
    float noiseValue = map3dNoiseToRange(
        fbm3Warp(noiseParameters, fragmentIn.worldPosition + material.noiseOffset + (material.varyWithTime ? uniformsShared.elapsedTime / 20 : 0.0)),
        -0.9,
        1.2);
    
    if (material.noiseThreshold > 0.0) {
        float falloffStrength = 3.0;
        float normalizedDistance = clamp((material.noiseThreshold - noiseValue) / material.noiseThreshold, 0.0, 1.0);
        float falloff = pow(normalizedDistance, falloffStrength);
        noiseValue = mix(noiseValue, 1.0, falloff);
    }
    
    float4 fragmentColor = mix(material.noiseColorA, material.noiseColorB, noiseValue);
"""
    }

    override class func getFragmentLightingCode(shaderVariant: FragmentFunctionVariant) -> String? {
"""
    bool enableLighting = uniformsShared.enableLighting && material.applyLight;
    bool enableShadows = uniformsShared.enableShadows && material.receiveShadow;

    float3 normal = getResolvedNormal(
        uniformsShared,
        material,
        fragmentIn.worldPosition,
        fragmentIn.worldNormal);

    ShadowResult shadowResult = calculateShadow(
        fragmentIn,
        textureArrayCascadedShadowMap,
        textureArrayCascadedShadowMapSampler,
        uniformsCascadeEndClipSpace,
        enableShadows);

    MaterialParameters materialParameters = resolveMaterial(
        material,
        globalMaterial,
        fragmentIn.worldPosition,
        normal,
        shadowResult.cascadeIndex,
        fragmentColor);

    fragmentColor = calculateLighting(
        uniformsShared,
        uniformsLights, 
        fragmentIn.worldPosition,
        normal,
        materialParameters, 
        shadowResult.shadowFactor,
        enableLighting);
"""
    }

    override class func getFragmentOutputCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
\(shaderVariant.isBloom 
    ? (shaderVariant.isTransparency
        ? alphaBloomOutput
        : bloomOutput)
    : (shaderVariant.isGBuffer 
        ? gbufferOutput 
        : (shaderVariant.isTransparency
            ? alphaOutput
            : standardOutput)))
"""
    }

    override class func getFragmentTransparencyCode(shaderVariant: FragmentFunctionVariant) -> String? {
"""
    float4 weightColor = fragmentColor;
    float transparencyWeight = max(
        min(
            1.0f, 
            max(
                max(
                    weightColor.r, 
                    weightColor.g), 
                weightColor.b) * weightColor.a), 
        weightColor.a) * clamp(0.03 / (1e-5 + pow(fragmentIn.clipSpacePosZ / 200, 4)), 
        1e-2,
    3e3);

    float4 transparencyColor = float4(fragmentColor.rgb * shadowResult.shadowFactor, fragmentColor.a);
    float revealage = transparencyColor.a;
    fragmentColor = float4(transparencyColor.rgb * transparencyColor.a, transparencyColor.a) * transparencyWeight;

"""
    }

    private static let standardOutput: String =
"""
    fragmentOut = fragmentColor;
"""

    private static let alphaOutput: String =
"""
    fragmentOut.color = fragmentColor;
    fragmentOut.revealage = revealage;
"""

    private static let bloomOutput: String =
"""
    fragmentOut.color = fragmentColor;
    
    // Simple bloom threshold
    float brightness = dot(fragmentColor.rgb, float3(0.2126, 0.7152, 0.0722));
    fragmentOut.brightness = (brightness > 1.0) ? fragmentColor : float4(0.0);
"""

    private static let alphaBloomOutput: String =
"""
    fragmentOut.color = fragmentColor;
    fragmentOut.revealage = revealage;
    
    float brightness = dot(fragmentColor.rgb, float3(0.2126, 0.7152, 0.0722));
    fragmentOut.brightness = (brightness > 1.0) ? fragmentColor : float4(0.0);
"""

    private static let gbufferOutput: String =
"""
    fragmentOut.normal = float4(fragmentIn.worldNormal, 1);
    fragmentOut.albedo = float4(fragmentColor.rgb, float(uniformsObject.materialId));
"""
}
