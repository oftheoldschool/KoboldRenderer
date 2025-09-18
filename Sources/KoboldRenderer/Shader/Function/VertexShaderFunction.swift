public struct VertexShaderVariantLayouts {
    let bufferLayout: String
    let outputLayout: String
    let attachmentLayout: String?

    public init(
        bufferLayout: String,
        outputLayout: String,
        attachmentLayout: String? = nil
    ) {
        self.bufferLayout = bufferLayout
        self.outputLayout = outputLayout
        self.attachmentLayout = attachmentLayout
    }
}

struct VertexShaderFunctionGroup {
    let functionName: String
    let perVariantLayouts: [VertexFunctionVariant: VertexShaderFunction]

    func getShaderFunction(_ shaderVariant: VertexFunctionVariant) -> VertexShaderFunction {
        return perVariantLayouts[shaderVariant]!
    }

    func getAllShaders() -> [VertexShaderFunction] {
        return Array(perVariantLayouts.values)
    }
}

class VertexShaderFunction {
    let functionName: String
    let shaderCode: String
    let vertexLayout: KVertexLayout?
    let outputLayout: KInOutLayout
    let bufferLayout: KBufferLayout
    let attachmentLayout: KAttachmentLayout?

    init(
        functionName: String,
        shaderCode: String,
        vertexLayout: KVertexLayout?,
        outputLayout: KInOutLayout,
        bufferLayout: KBufferLayout,
        attachmentLayout: KAttachmentLayout? = nil
    ) {
        self.functionName = functionName
        self.shaderCode = shaderCode
        self.vertexLayout = vertexLayout
        self.outputLayout = outputLayout
        self.bufferLayout = bufferLayout
        self.attachmentLayout = attachmentLayout
    }
}
