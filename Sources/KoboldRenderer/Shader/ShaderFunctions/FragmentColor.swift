class FragmentShaderFunctionTemplateColor: FragmentShaderFunctionTemplate {
    override class var functionName: String { "colorFragment" }
    override class var inputLayout: String { "basicFragment" }

    // todo: can we dedupe these and remove the need for variants with "instanced" in the name?
    // can we switch the FragmentFunctionaVariant to an OptionSet? How would we resolve? Most specific to least?
    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "colorPlusDepth"),
            .instancedColor: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "colorPlusDepth"),

            .colorAlpha: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "alpha",
                attachmentLayout: "colorPlusRevealagePlusDepth"),
            .instancedColorAlpha: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "alpha",
                attachmentLayout: "colorPlusRevealagePlusDepth"),

            .colorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "forwardBloom",
                attachmentLayout: "colorPlusBrightnessPlusDepth"),
            .instancedColorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "forwardBloom",
                attachmentLayout: "colorPlusBrightnessPlusDepth"),

            .colorAlphaPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "alphaBloom",
                attachmentLayout: "colorPlusBrightnessPlusRevealagePlusDepth"),
            .instancedColorAlphaPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "alphaBloom",
                attachmentLayout: "colorPlusBrightnessPlusRevealagePlusDepth"),

            .gbuffer: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "gbuffer",
                attachmentLayout: "gbuffer"),
            .instancedGBuffer: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "gbuffer",
                attachmentLayout: "gbuffer"),
        ]
    }

    // todo: not required for gbuffer pass. how will we handle this?
    override class var textureLayout: String {
        "cascadedShadowMap"
    }

    override class var materialLayout: String {
        "none"
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
        uniformsShared.enableShadows && material.receiveShadow);

    float4 resolvedColor = getResolvedColor(
        material,
        globalMaterial,
        fragmentIn.worldPosition,
        normal,
        shadowResult.cascadeIndex,
        fragmentColor.xyz);

    float baseAlpha = fragmentColor.a;

    fragmentColor = calculateLighting(
        uniformsShared,
        uniformsLights, 
        fragmentIn.worldPosition,
        normal,
        resolvedColor.rgb, 
        baseAlpha, 
        shadowResult.shadowFactor,
        uniformsShared.enableLighting && material.applyLight);
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
    // Calculate weight using unshadowed color
    float4 weightColor = float4(fragmentColor.rgb, baseAlpha); // Use lit but unshadowed color
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

    // Apply shadows to final transparency color after weight calculation
    float4 transparencyColor = float4(fragmentColor.rgb * shadowResult.shadowFactor, baseAlpha);
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
