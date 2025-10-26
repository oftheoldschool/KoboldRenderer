class VertexShaderFunctionTemplateBasic: VertexShaderFunctionTemplate {
    override class var functionName: String { "basicVertex" }
    override class var vertexLayout: String { "BasicVertex" }
    override class var perVariantLayouts: [VertexFunctionVariant: VertexShaderVariantLayouts] {
        [
            .single: VertexShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightSpaceVolumes",
                outputLayout: "FullFragmentInput"),
            .instanced: VertexShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightSpaceVolumes",
                outputLayout: "FullFragmentInput"),
            .singleShadow: VertexShaderVariantLayouts(
                bufferLayout: "BaseUniforms",
                outputLayout: "float4",
                attachmentLayout: "Depth"),
            .instancedShadow: VertexShaderVariantLayouts(
                bufferLayout: "BaseUniforms",
                outputLayout: "float4",
                attachmentLayout: "Depth"),
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
    vertexOut.normal = vertexIn.normal;
    vertexOut.texCoords = vertexIn.texCoords;
    vertexOut.localPosition = vertexIn.position;
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
