public struct FragmentShaderVariantLayouts {
    let bufferLayout: String
    let outputLayout: String
    let attachmentLayout: String

    public init(bufferLayout: String, outputLayout: String, attachmentLayout: String) {
        self.bufferLayout = bufferLayout
        self.outputLayout = outputLayout
        self.attachmentLayout = attachmentLayout
    }
}

struct FragmentShaderFunctionGroup {
    let functionName: String
    let perVariantLayouts: [FragmentFunctionVariant: FragmentShaderFunction]

    func getShaderFunction(_ shaderVariant: FragmentFunctionVariant) -> FragmentShaderFunction? {
        return perVariantLayouts[shaderVariant]
    }

    func getAllShaders() -> [FragmentShaderFunction] {
        return Array(perVariantLayouts.values)
    }
}

class FragmentShaderFunction {
    let functionName: String
    let shaderCode: String
    let inputLayout: KInOutLayout
    let outputLayout: KInOutLayout
    let bufferLayout: KBufferLayout
    let textureLayout: KTextureLayout
    let materialLayout: KMaterialLayout
    let attachmentLayout: KAttachmentLayout?

    init(
        functionName: String,
        shaderVariant: FragmentFunctionVariant,
        shaderCode: String,
        inputLayout: KInOutLayout,
        outputLayout: KInOutLayout,
        bufferLayout: KBufferLayout,
        textureLayout: KTextureLayout,
        materialLayout: KMaterialLayout,
        attachmentLayout: KAttachmentLayout,
        variableMap: [String: String]
    ) {
        self.functionName = functionName
        self.shaderCode = shaderCode
        self.inputLayout = inputLayout
        self.outputLayout = outputLayout
        self.bufferLayout = bufferLayout
        self.textureLayout = textureLayout
        self.materialLayout = materialLayout
        self.attachmentLayout = attachmentLayout
    }
}

