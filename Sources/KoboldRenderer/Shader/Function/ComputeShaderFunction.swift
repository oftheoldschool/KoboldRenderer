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
    let bufferLayout: BufferLayout
    let textureLayout: TextureLayout

    init(
        functionName: String,
        shaderCode: String,
        bufferLayout: BufferLayout,
        textureLayout: TextureLayout
    ) {
        self.functionName = functionName
        self.shaderCode = shaderCode
        self.bufferLayout = bufferLayout
        self.textureLayout = textureLayout
    }
}
