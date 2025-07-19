open class VertexShaderFunctionTemplate {
    class var functionName: String { fatalError("unimplemented") }
    class var vertexConstantCode: String? { nil }
    class var vertexPositionCode: String { fatalError("unimplemented") }
    class var vertexAnimationCode: String? { nil }
    class var vertexAdditionalCode: String? { nil }
    class var vertexLayout: String? { fatalError("unimplemented") }
    class var perVariantLayouts: [VertexFunctionVariant: VertexShaderVariantLayouts] { fatalError("unimplemented") }

    static func createFunctionGroup(
        layoutLibrary: LayoutLibrary,
        variableMap: [String: String]
    ) -> VertexShaderFunctionGroup {
        let shaders: [VertexFunctionVariant: VertexShaderFunction] = perVariantLayouts.reduce(into: [:]) { result, element in
            let (shaderVariant, perVariantLayout) = element

            let instancedPrefix = shaderVariant.isInstanced ? "instanced_" : ""
            let shadowPrefix = shaderVariant.isShadow ? "shadow_" : ""
            let animationPrefix = shaderVariant.isAnimated ? "animated_" : ""
            let finalFunctionName = "\(instancedPrefix)\(animationPrefix)\(shadowPrefix)\(functionName)"

            let shaderCode = Self.generateShaderCode(
                functionName: finalFunctionName,
                vertexPositionCode: vertexPositionCode,
                vertexAnimationCode: vertexAnimationCode,
                vertexAdditionalCode: vertexAdditionalCode,
                vertexConstantCode: vertexConstantCode,
                vertexLayout: vertexLayout.flatMap { layoutLibrary.vertexLayouts[$0] },
                outputLayout: layoutLibrary.inOutLayouts[perVariantLayout.outputLayout]!,
                bufferLayout: layoutLibrary.bufferLayouts[perVariantLayout.bufferLayout]!,
                isInstanced: shaderVariant.isInstanced,
                isShadow: shaderVariant.isShadow,
                isAnimated: shaderVariant.isAnimated)

            result[shaderVariant] = VertexShaderFunction(
                functionName: finalFunctionName,
                shaderCode: variableMap.reduce(shaderCode) { (acc, next) in
                    acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
                },
                vertexLayout: vertexLayout.flatMap { layoutLibrary.vertexLayouts[$0] },
                outputLayout: layoutLibrary.inOutLayouts[perVariantLayout.outputLayout]!,
                bufferLayout: layoutLibrary.bufferLayouts[perVariantLayout.bufferLayout]!,
                attachmentLayout: perVariantLayout.attachmentLayout.map {
                    layoutLibrary.attachmentLayouts[$0]!
                }
            )
        }
        return VertexShaderFunctionGroup(
            functionName: functionName,
            perVariantLayouts: shaders)
    }
    
    static func generateShaderCode(
        functionName: String,
        vertexPositionCode: String,
        vertexAnimationCode: String?,
        vertexAdditionalCode: String?,
        vertexConstantCode: String?,
        vertexLayout: VertexLayout?,
        outputLayout: InOutLayout,
        bufferLayout: BufferLayout,
        isInstanced: Bool,
        isShadow: Bool,
        isAnimated: Bool
    ) -> String {
        let functionParameters = bufferLayout.bufferLayoutBindings.map { bufferLayoutBinding in
            let bufferLayoutBindingType = bufferLayoutBinding.type

            // todo: grab parameter name from enum rather than hard coding
            let (referenceType, parameterName) = if case .uniformsObject = bufferLayoutBindingType, isInstanced {
                ("*", "instancedObjectUniforms")
            } else if case .pointer = bufferLayoutBindingType.datatype {
                ("*", bufferLayoutBindingType.description)
            } else {
                ("&", bufferLayoutBindingType.description)
            }

            return "constant \(bufferLayoutBindingType.datatype.description) \(referenceType) \(parameterName) [[buffer(\(bufferLayoutBinding.index))]]"
        }
        + ["uint vertexID [[ vertex_id ]]"]
        + (isInstanced ? ["uint instance_id [[instance_id]]"] : [])

        return
"""
\(vertexConstantCode.map { $0 } ?? "")

vertex \(outputLayout.name) \(functionName)(
    \(vertexLayout != nil ? "\(vertexLayout!.name) vertexIn [[stage_in]]," : "")
    \(functionParameters.joined(separator: ",\n    "))
)
{
    \(isInstanced ? "DrawObjectUniforms uniformsObject = instancedObjectUniforms[instance_id];" : "")
    \(isShadow ? "" : "\(outputLayout.name) vertexOut;")
\(isAnimated ? vertexAnimationCode ?? vertexPositionCode : vertexPositionCode)
\(!isShadow ? vertexAdditionalCode ?? "" : "")
    \(isInstanced && !isShadow ? "vertexOut.instanceId = instance_id;" : "")
    return \(isShadow ? "outputPosition" : "vertexOut");
}
"""
    }
}
