class FragmentShaderFunctionTemplateTexture: FragmentShaderFunctionTemplate {
    override class var functionName: String { "texturedFragment" }
    override class var inputLayout: String { "fullFragment" }
    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "colorPlusDepth"),
            .colorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "forwardBloom",
                attachmentLayout: "colorPlusBrightnessPlusDepth"),
            .gbuffer: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "gbuffer",
                attachmentLayout: "gbuffer"),
            .instancedColor: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "colorPlusDepth"),
            .instancedColorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightUniforms",
                outputLayout: "forwardBloom",
                attachmentLayout: "colorPlusBrightnessPlusDepth"),
            .instancedGBuffer: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "gbuffer",
                attachmentLayout: "gbuffer"),
        ]
    }

    override class var textureLayout: String {
        "cascadedShadowMap"
    }
    
    override class var materialLayout: String {
        "textured"
    }

    override class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
    constant MaterialUniforms & material = materials[uniformsObject.materialId];
    constant MaterialUniforms & globalMaterial = materials[uniformsShared.globalMaterialId];
    float4 fragmentColor = textureBaseColor.sample(textureBaseColorSampler, fragmentIn.texCoords);
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
        uniformsShared.enableShadows && material.applyLight);

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
        uniformsShared.enableLighting && material.applyLight);
"""
    }

    override class func getFragmentOutputCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
\(shaderVariant.isBloom ? bloomOutput : (shaderVariant.isGBuffer ? gbufferOutput : standardOutput))
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
}

