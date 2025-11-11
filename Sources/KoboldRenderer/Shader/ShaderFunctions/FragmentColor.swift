class FragmentShaderFunctionTemplateColor: FragmentShaderFunctionTemplate {
    override class var functionName: String { "colorFragment" }
    override class var inputLayout: String { "FullFragmentInput" }

    // todo: can we dedupe these and remove the need for variants with "instanced" in the name?
    // can we switch the FragmentFunctionaVariant to an OptionSet? How would we resolve? Most specific to least?
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

    // todo: not required for gbuffer pass. how will we handle this?
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
    float4 fragmentColor = material.color;
"""
    }

    override class func getFragmentLightingCode(shaderVariant: FragmentFunctionVariant) -> String? {
"""
    bool enableLighting = uniformsLighting.enableLighting && material.applyLight;
    bool enableShadows = uniformsLighting.enableShadows && material.receiveShadow;

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
        enableShadows,
        uniformsLighting);

    MaterialParameters materialParameters = resolveMaterial(
        material,
        globalMaterial,
        fragmentIn.worldPosition,
        normal,
        shadowResult.cascadeIndex,
        fragmentColor);

    fragmentColor = calculateLighting(
        uniformsShared,
        uniformsLighting,
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
    float4 weightColor = fragmentColor; // Use lit but unshadowed color
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

    private static let gbufferOutput: String =
"""
    fragmentOut = {
        .normal = float4(fragmentIn.worldNormal, 1),
        .albedo = float4(fragmentColor.rgb, float(uniformsObject.materialId)),
    };
"""

    private static let bloomOutput: String =
"""
    float4 brightness = calculateBloom(
        fragmentColor,
        uniformsShared.bloomThreshold,
        uniformsShared.bloomMultiplier
    );
    fragmentOut = {
        .color = fragmentColor,
        .brightness = brightness,
    };
"""

    private static let alphaOutput: String =
"""
    fragmentOut = {
        .revealage = revealage,
        .color = fragmentColor,
    };
"""

    private static let alphaBloomOutput: String =
"""
    float4 brightness = calculateBloom(
        fragmentColor,
        uniformsShared.bloomThreshold,
        uniformsShared.bloomMultiplier
    );
    fragmentOut = {
        .revealage = revealage,
        .color = fragmentColor,
        .brightness = brightness,
    };
"""
}
