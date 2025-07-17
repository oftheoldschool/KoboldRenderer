class ComputeShaderFunctionTemplate {
    class var functionName: String { fatalError("unimplemented") }
    class var perVariantLayouts: [ComputeFunctionVariant: ComputeShaderVariantLayouts] { fatalError("unimplemented") }
    class var textureSizeValidation: Bool { false }

    class func getComputeCode(shaderVariant: ComputeFunctionVariant) -> String { fatalError("unimplemented") }

    static func createFunctionGroup(
        layoutLibrary: LayoutLibrary,
        variableMap: [String: String]
    ) -> ComputeShaderFunctionGroup {
        let shaders: [ComputeFunctionVariant: ComputeShaderFunction] = perVariantLayouts.reduce(into: [:]) { result, element in
            let (shaderVariant, perVariantLayout) = element

            // todo: this variation stuff might not generalise well, since bloom is specific to
            // rendering functions. maybe there should be specific types of compute functions
            let bloomPrefix = shaderVariant.isBloom ? "bloom_" : ""
            let finalFunctionName = "\(bloomPrefix)\(functionName)"

            let shaderCode = Self.getFunction(
                functionName: finalFunctionName,
                shaderVariant: shaderVariant,
                computeCode: getComputeCode(shaderVariant: shaderVariant),
                bufferLayout: layoutLibrary.bufferLayouts[perVariantLayout.bufferLayout]!,
                textureLayout: layoutLibrary.textureLayouts[perVariantLayout.textureLayout]!,
                variableMap: variableMap)
            result[shaderVariant] = ComputeShaderFunction(
                functionName: finalFunctionName,
                shaderCode: shaderCode,
                bufferLayout: layoutLibrary.bufferLayouts[perVariantLayout.bufferLayout]!,
                textureLayout: layoutLibrary.textureLayouts[perVariantLayout.textureLayout]!)
        }
        return ComputeShaderFunctionGroup(
            functionName: functionName,
            perVariantLayouts: shaders)
    }

    static func getFunction(
        functionName: String,
        shaderVariant: ComputeFunctionVariant,
        computeCode: String,
        bufferLayout: BufferLayout,
        textureLayout: TextureLayout,
        variableMap: [String: String]
    ) -> String {
        let functionParameters = bufferLayout.bufferLayoutBindings.map { bufferLayoutBinding in
            let bufferLayoutBindingType = bufferLayoutBinding.type

            let (referenceType, parameterName) = if case .pointer = bufferLayoutBindingType.datatype {
                ("*", bufferLayoutBindingType.description)
            } else {
                ("&", bufferLayoutBindingType.description)
            }

            return "constant \(bufferLayoutBindingType.datatype.description) \(referenceType) \(parameterName) [[buffer(\(bufferLayoutBinding.index))]]"
        }
        + textureLayout.textureLayoutBindings.flatMap { textureLayoutBinding in
            let bindingType = textureLayoutBinding.type
            let accessType = textureLayoutBinding.accessType
            let bindingIndex = textureLayoutBinding.index

            let textureParameter = "\(bindingType.dataType)<\(bindingType.primitiveType), access::\(accessType)> \(bindingType) [[texture(\(bindingIndex))]]"
            let samplerParameter = "sampler \(bindingType)Sampler [[sampler(\(bindingIndex))]]"

            return if accessType == .sample {
                [textureParameter, samplerParameter]
            } else {
                [textureParameter]
            }
        }
        + ["uint2 gid [[thread_position_in_grid]]"]

    return """
kernel void \(functionName)(
    \(functionParameters.joined(separator: ",\n    "))
) {

\(textureSizeValidation ?
"""
    if (gid.x >= textureComputeOutput.get_width() || gid.y >= textureComputeOutput.get_height()) {
        return;
    }
""" : "")

\(computeCode)

}
"""
    }
}
