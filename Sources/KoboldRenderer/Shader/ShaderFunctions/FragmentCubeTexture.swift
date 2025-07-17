class FragmentShaderFunctionTemplateCubeTexture: FragmentShaderFunctionTemplate {
    override class var functionName: String { "cubeTexturedFragment" }
    override class var inputLayout: String { "basicFragment" }
    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "float4",
                attachmentLayout: "colorPlusDepth"),
            .colorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "forwardBloom",
                attachmentLayout: "colorPlusBrightnessPlusDepth"),
            .gbuffer: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "gbuffer",
                attachmentLayout: "gbuffer")
        ]
    }
    override class var textureLayout: String {
        "none"
    }
    override class var materialLayout: String {
        "cubeTextured"
    }

    override class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
    constant MaterialUniforms & material = materials[uniformsObject.materialId];
    constant MaterialUniforms & globalMaterial = materials[uniformsShared.globalMaterialId];
    
    // hack because the world is coming out flipped in the yz plane...
    float3 sampleWorldPosition = fragmentIn.worldPosition;
    sampleWorldPosition.z = -sampleWorldPosition.z;
    
    float4 sampledColor = textureCubeMap.sample(textureCubeMapSampler, sampleWorldPosition);
    float4 resolvedColor = getResolvedColor(
        material,
        globalMaterial,
        fragmentIn.worldPosition,
        fragmentIn.worldNormal,
        0,
        sampledColor.xyz);
    float4 fragmentColor = float4(resolvedColor.rgb, sampledColor.a);
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
        .normal = float4(fragmentIn.normal, 1),
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

