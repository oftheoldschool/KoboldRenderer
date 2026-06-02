public class VertexShaderFunctionTemplateBillboard: VertexShaderFunctionTemplate {
    public override class var functionName: String { "billboardVertex" }
    public override class var vertexLayout: String { "BasicVertex" }
    public override class var perVariantLayouts: [VertexFunctionVariant: VertexShaderVariantLayouts] {
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

    public override class var vertexPositionCode: String {
"""
    float3 worldCenter = float3(uniformsObject.model[3][0], uniformsObject.model[3][1], uniformsObject.model[3][2]);
    float scaleX = length(float3(uniformsObject.model[0][0], uniformsObject.model[0][1], uniformsObject.model[0][2]));
    float scaleZ = length(float3(uniformsObject.model[2][0], uniformsObject.model[2][1], uniformsObject.model[2][2]));

    float3 right = float3(uniformsShared.invViewMatrix[0][0], uniformsShared.invViewMatrix[0][1], uniformsShared.invViewMatrix[0][2]);
    float3 up = float3(uniformsShared.invViewMatrix[1][0], uniformsShared.invViewMatrix[1][1], uniformsShared.invViewMatrix[1][2]);

    float4 worldPosition = float4(worldCenter + right * vertexIn.position.x * scaleX + up * vertexIn.position.z * scaleZ, 1);
    float4x4 viewProjectionMatrix = uniformsShared.viewProjection;
    float4 outputPosition = viewProjectionMatrix * worldPosition;
    float3 worldNormal = normalize(uniformsShared.cameraPosition - worldCenter);
"""
    }

    public override class var vertexAdditionalCode: String? {
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
