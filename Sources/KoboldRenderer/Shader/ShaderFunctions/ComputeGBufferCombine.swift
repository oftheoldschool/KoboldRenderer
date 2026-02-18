import Metal
import simd

class ComputeShaderFunctionTemplateGBufferCombine: ComputeShaderFunctionTemplate {
    override class var functionName: String { "computeShaderGBufferCombine" }
    override class var perVariantLayouts: [ComputeFunctionVariant: ComputeShaderVariantLayouts] {
        [
            .color: ComputeShaderVariantLayouts(bufferLayout: "GBufferCombine", textureLayout: "GBufferCombine"),
            .colorPlusBloom: ComputeShaderVariantLayouts(bufferLayout: "GBufferCombine", textureLayout: "GBufferCombineBloom"),
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

    // Reproject world position to clip space to match forward path's clipSpacePosZ
    float4 clipFromWorld = uniformsShared.viewProjection * float4(worldSpacePos.xyz, 1.0);

    ShadowCalculationData shadowCalculationData = getShadowCalculationData(
        worldSpacePos.xyz,
        clipFromWorld.z,
        uniformsLightSpaceVolumes);

    constant MaterialUniforms & material = materials[materialId];
    constant MaterialUniforms & globalMaterial = materials[uniformsShared.globalMaterialId];

    bool enableLighting = uniformsLighting.enableLighting && material.applyLight;
    bool enableShadows = uniformsLighting.enableShadows && material.receiveShadow;

//    ShadowResult shadowResult {};
    ShadowResult shadowResult = calculateShadow(
        shadowCalculationData,
        textureArrayCascadedShadowMap,
        textureArrayCascadedShadowMapSampler,
        uniformsCascadeEndClipSpace,
        enableShadows,
        uniformsLighting,
        uniformsLights,
        uniformsOccluders);

    MaterialParameters materialParameters = resolveMaterial(
        material,
        globalMaterial,
        worldSpacePos.xyz,
        normal,
        shadowResult.cascadeIndex,
        float4(albedo.rgb, 1));

    float4 finalColor = calculateLighting(
        uniformsShared,
        uniformsLighting,
        uniformsLights,
        worldSpacePos.xyz,
        normal,
        materialParameters,
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
