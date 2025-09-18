struct ComputeShaderVariantLayouts {
    let bufferLayout: String
    let textureLayout: String

    init(
        bufferLayout: String,
        textureLayout: String
    ) {
        self.bufferLayout = bufferLayout
        self.textureLayout = textureLayout
    }
}

struct ComputeShaderFunctionGroup {
    let functionName: String
    let perVariantLayouts: [ComputeFunctionVariant: ComputeShaderFunction]

    func getShaderFunction(_ shaderVariant: ComputeFunctionVariant) -> ComputeShaderFunction {
        return perVariantLayouts[shaderVariant]!
    }

    func getAllShaders() -> [ComputeShaderFunction] {
        return Array(perVariantLayouts.values)
    }
}

class ComputeShaderFunction {
    let functionName: String
    let shaderCode: String
    let bufferLayout: KBufferLayout
    let textureLayout: KTextureLayout

    init(
        functionName: String,
        shaderCode: String,
        bufferLayout: KBufferLayout,
        textureLayout: KTextureLayout
    ) {
        self.functionName = functionName
        self.shaderCode = shaderCode
        self.bufferLayout = bufferLayout
        self.textureLayout = textureLayout
    }
}
