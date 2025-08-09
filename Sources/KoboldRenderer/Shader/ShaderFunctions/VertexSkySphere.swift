class VertexShaderFunctionTemplateSkySphere: VertexShaderFunctionTemplate {
    override class var functionName: String { "skyboxVertex" }
    override class var vertexLayout: String { "skyboxVertex" }
    override class var perVariantLayouts: [VertexFunctionVariant: VertexShaderVariantLayouts] {
        [
            .single: VertexShaderVariantLayouts(
                bufferLayout: "baseUniforms",
                outputLayout: "fullFragment"),
        ]
    }

    override class var vertexPositionCode: String {
"""
    float4 worldPosition = uniformsObject.model * float4(vertexIn.position, 1);
    float4x4 viewProjectionMatrix = uniformsShared.noTranslationViewProjection;
    float4 outputPosition = viewProjectionMatrix * worldPosition;
"""
    }

    override class var vertexAdditionalCode: String? {
"""
    vertexOut.position = outputPosition;
    vertexOut.normal = vertexIn.normal;

    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = uniformsObject.normalMatrix * vertexIn.normal;
"""
    }
}
