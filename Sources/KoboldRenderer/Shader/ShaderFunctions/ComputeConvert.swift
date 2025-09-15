import Metal

class ComputeShaderFunctionTemplateConvert: ComputeShaderFunctionTemplate {
    override class var functionName: String { "convertRGBA32FloatToBGRA8Unorm" }
    override class var perVariantLayouts: [ComputeFunctionVariant: ComputeShaderVariantLayouts] {
        [
            .color: ComputeShaderVariantLayouts(bufferLayout: "None", textureLayout: "ConvertRGBA32FloatToBGRA8Unorm"),
        ]
    }
    override class var textureSizeValidation: Bool { true }
    override class func getComputeCode(shaderVariant: ComputeFunctionVariant) -> String {
"""
    float4 color = textureComputeInput.read(gid);
    color = clamp(color, 0.0, 1.0);
    float4 outputColor = color;
    textureComputeOutput.write(outputColor, gid);
"""
    }
}
