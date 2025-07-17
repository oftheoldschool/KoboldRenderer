class VertexShaderFunctionTemplateBasic: VertexShaderFunctionTemplate {
    override class var functionName: String { "basicVertex" }
    override class var vertexLayout: String { "basicVertex" }
    override class var perVariantLayouts: [VertexFunctionVariant: VertexShaderVariantLayouts] {
        [
            .single: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightSpaceVolumes",
                outputLayout: "basicFragment"),
            .instanced: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightSpaceVolumes",
                outputLayout: "basicFragment"),
            .singleShadow: VertexShaderVariantLayouts(
                bufferLayout: "baseUniforms",
                outputLayout: "float4",
                attachmentLayout: "depth"),
            .instancedShadow: VertexShaderVariantLayouts(
                bufferLayout: "baseUniforms",
                outputLayout: "float4",
                attachmentLayout: "depth"),
        ]
    }

    override class var vertexPositionCode: String {
"""
    float4 worldPosition = uniformsObject.model * float4(vertexIn.position, 1);
    float4x4 viewProjectionMatrix = uniformsShared.viewProjection;
    float4 outputPosition = viewProjectionMatrix * worldPosition;
    float3 worldNormal = normalize(uniformsObject.normalMatrix * vertexIn.normal);
"""
    }

    override class var vertexAdditionalCode: String? {
"""
    vertexOut.position = outputPosition;
    vertexOut.texCoords = vertexIn.texCoords;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = worldNormal;
    vertexOut.clipSpacePosZ = vertexOut.position.z;

    REPEAT(
        ${CASCADED_SHADOW_NUM_CASCADES}, 
        CALCULATE_LIGHTSPACE_POS, 
        worldPosition, 
        uniformsLightSpaceVolumes,
        vertexOut.lightSpacePos_)
"""
    }
}
