import Metal
import simd

class ComputeShaderFunctionTemplateGBufferCombine: ComputeShaderFunctionTemplate {
    override class var functionName: String { "computeShaderGBufferCombine" }
    override class var perVariantLayouts: [ComputeFunctionVariant: ComputeShaderVariantLayouts] {
        [
            .color: ComputeShaderVariantLayouts(bufferLayout: "gbufferCombine", textureLayout: "gbufferCombine"),
            .colorPlusBloom: ComputeShaderVariantLayouts(bufferLayout: "gbufferCombine", textureLayout: "gbufferCombineBloom"),
        ]
    }
    override class var textureSizeValidation: Bool { true }
    override class func getComputeCode(shaderVariant: ComputeFunctionVariant) -> String {
"""
    float depth = textureGBufferDepth.read(gid);
    float3 normal = normalize(textureGBufferNormals.read(gid).xyz);
    float4 albedo = textureGBufferAlbedos.read(gid);
    int materialId = int(albedo.a);

    // Calculate normalized device coordinates (NDC)
    float2 texCoord = float2(gid) / float2(textureComputeOutput.get_width(), textureComputeOutput.get_height());
    float2 ndcXY = texCoord * 2.0 - 1.0;
    ndcXY.y = -ndcXY.y;
    
    // Create a position in clip space
    float4 clipSpacePos = float4(ndcXY, depth, 1.0);
    
    // Transform to world space using the inverse view-projection matrix
    // A limitation of this is that it assumes all fragments were created as a result of
    // regular view projection, while the skybox removes the translation aspect of the view
    // This is fine for lighting calculations as the skybox isn't affected by lighting, but 
    // debug information for skybox in deferred rendering won't be accurate
    float4 worldSpacePos = uniformsShared.invViewProjection * clipSpacePos;
    worldSpacePos /= worldSpacePos.w; // Perspective divide

    // Transform to view space using inverse projection matrix
    float4 viewSpacePos = uniformsShared.invProjectionMatrix * clipSpacePos;
    viewSpacePos /= viewSpacePos.w;
    float viewSpaceDepth = -viewSpacePos.z;
    
    ShadowCalculationData shadowCalculationData = getShadowCalculationData(
        worldSpacePos.xyz,
        viewSpaceDepth,
        uniformsLightSpaceVolumes);

    constant MaterialUniforms & material = materials[materialId];
    constant MaterialUniforms & globalMaterial = materials[uniformsShared.globalMaterialId];
    bool enableLighting = uniformsShared.enableLighting && material.applyLight;
    bool enableShadows = uniformsShared.enableShadows && material.applyLight;

    ShadowResult shadowResult = calculateShadow(
        shadowCalculationData,
        textureArrayCascadedShadowMap,
        textureArrayCascadedShadowMapSampler,
        uniformsCascadeEndClipSpace,
        enableShadows);

    float4 resolvedColor = getResolvedColor(
        material,
        globalMaterial,
        worldSpacePos.xyz,
        normal,
        shadowResult.cascadeIndex,
        albedo.rgb);

    float4 finalColor = calculateLighting(
        uniformsShared,
        uniformsLights,
        worldSpacePos.xyz,
        normal,
        resolvedColor.rgb,
        1, 
        shadowResult.shadowFactor,
        enableLighting);

    float4 outputColor = float4(finalColor.rgb, 1.0);
    textureComputeOutput.write(outputColor, gid);
""" + (shaderVariant.isBloom ? """
    float4 brightness = calculateBloom(
        float4(finalColor.rgb, 1),
        uniformsShared.bloomThreshold,
        uniformsShared.bloomMultiplier
    );
    textureComputeBloomOutput.write(float4(brightness.rgb, 1.0), gid);
""" : "")
    }
}
