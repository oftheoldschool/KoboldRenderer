class FragmentShaderFunctionTemplateTexture: FragmentShaderFunctionTemplate {
    override class var functionName: String { "texturedFragment" }
    override class var inputLayout: String { "FullFragmentInput" }
    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "ColorPlusDepth"),
            .colorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "BloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusDepth"),
            .gbuffer: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusMaterials",
                outputLayout: "GBufferFragmentOutput",
                attachmentLayout: "GBuffer"),
            .instancedColor: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "ColorPlusDepth"),
            .instancedColorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "BloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusDepth"),
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
        "Textured"
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
        uniformsShared.enableShadows && material.applyLight,
        uniformsShared);

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
