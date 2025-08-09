class VertexShaderFunctionTemplatePassThrough: VertexShaderFunctionTemplate {
    override class var functionName: String { "passThroughVertex" }
    override class var vertexLayout: String { "none" }
    override class var perVariantLayouts: [VertexFunctionVariant: VertexShaderVariantLayouts] {
        [
            .single: VertexShaderVariantLayouts(
                bufferLayout: "none",
                outputLayout: "fullFragment"),
        ]
    }

    override class var vertexConstantCode: String? {
"""
constant float4 passThroughVertexPositions[4] = {
    float4(-1, -1, 0, 1),
    float4(1, -1, 0, 1),
    float4(1, 1, 0, 1),
    float4(-1, 1, 0, 1),
};

constant int passThroughIndices[6] = {
    0, 1, 2, 0, 2, 3,
};
"""
    }

    override class var vertexPositionCode: String {
"""
    vertexOut.position = passThroughVertexPositions[passThroughIndices[vertexID]];
    vertexOut.texCoords = float2((vertexOut.position.x + 1) * 0.5 , (vertexOut.position.y + 1) * -0.5);
"""
    }
}
