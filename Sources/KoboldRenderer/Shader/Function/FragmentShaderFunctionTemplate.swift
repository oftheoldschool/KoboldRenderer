open class FragmentShaderFunctionTemplate {
    open class var functionName: String { fatalError("unimplemented") }
    open class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] { fatalError("unimplemented") }
    open class var compileForwardVariantsInDeferred: Bool { false }

    open class var inputLayout: String { fatalError("unimplemented") }
    open class var textureLayout: String { fatalError("unimplemented") }
    open class var materialLayout: String { fatalError("unimplemented") }

    open class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String { fatalError("unimplemented") }
    open class func getFragmentLightingCode(shaderVariant: FragmentFunctionVariant) -> String? { nil }
    open class func getFragmentOutputCode(shaderVariant: FragmentFunctionVariant) -> String { fatalError("unimplemented") }
    open class func getFragmentTransparencyCode(shaderVariant: FragmentFunctionVariant) -> String? { nil }

    static func createFunctionGroup(
        layoutLibrary: LayoutLibrary,
        variableMap: [String: String],
        renderingMode: KRRenderingMode
    ) -> FragmentShaderFunctionGroup {
        let hasTransparencyVariants = perVariantLayouts.keys.contains { $0.isTransparency }
        let supportedVariants: [FragmentFunctionVariant: FragmentShaderVariantLayouts] = perVariantLayouts.filter { element in
            let (shaderVariant, _) = element
            return switch renderingMode {
            case .deferred:
                compileForwardVariantsInDeferred
                    || shaderVariant.isGBuffer
                    || shaderVariant.isTransparency
                    || (hasTransparencyVariants && !shaderVariant.isGBuffer)
            case .forward: !shaderVariant.isGBuffer
            }
        }

        let variantsToBuild = supportedVariants.isEmpty ? perVariantLayouts : supportedVariants

        let shaders: [FragmentFunctionVariant: FragmentShaderFunction] = variantsToBuild.reduce(into: [:]) { result, element in
            let (shaderVariant, perVariantLayout) = element

            let instancedPrefix = shaderVariant.isInstanced ? "instanced_" : ""
            let bloomPrefix = shaderVariant.isBloom ? "bloom_" : ""
            let gbufferPrefix = shaderVariant.isGBuffer ? "gbuffer_" : ""
            let transparencyPrefix = shaderVariant.isTransparency ? "transparency_" : ""
            let finalFunctionName = "\(instancedPrefix)\(transparencyPrefix)\(bloomPrefix)\(gbufferPrefix)\(functionName)"

            let shaderCode = Self.generateShaderCode(
                functionName: finalFunctionName,
                shaderVariant: shaderVariant,
                fragmentCode: getFragmentCode(shaderVariant: shaderVariant),
                fragmentLightingCode: getFragmentLightingCode(shaderVariant: shaderVariant),
                fragmentTransparencyCode: getFragmentTransparencyCode(shaderVariant: shaderVariant),
                fragmentOutputCode: getFragmentOutputCode(shaderVariant: shaderVariant),
                inputLayout: layoutLibrary.inOutLayouts[inputLayout]!,
                outputLayout: layoutLibrary.inOutLayouts[perVariantLayout.outputLayout]!,
                bufferLayout: layoutLibrary.bufferLayouts[perVariantLayout.bufferLayout]!,
                textureLayout: layoutLibrary.textureLayouts[textureLayout]!,
                materialLayout: layoutLibrary.materialLayouts[materialLayout]!,
                attachmentLayout: layoutLibrary.attachmentLayouts[perVariantLayout.attachmentLayout]!,
                isInstanced: shaderVariant.isInstanced
            )

            result[shaderVariant] = FragmentShaderFunction(
                functionName: finalFunctionName,
                shaderVariant: shaderVariant,
                shaderCode: shaderCode,
                inputLayout: layoutLibrary.inOutLayouts[inputLayout]!,
                outputLayout: layoutLibrary.inOutLayouts[perVariantLayout.outputLayout]!,
                bufferLayout: layoutLibrary.bufferLayouts[perVariantLayout.bufferLayout]!,
                textureLayout: layoutLibrary.textureLayouts[textureLayout]!,
                materialLayout: layoutLibrary.materialLayouts[materialLayout]!,
                attachmentLayout: layoutLibrary.attachmentLayouts[perVariantLayout.attachmentLayout]!,
                variableMap: variableMap)
        }
        return FragmentShaderFunctionGroup(
            functionName: functionName,
            perVariantLayouts: shaders)
    }

    private static func generateNearCameraFadeCode(
        inputLayout: KInOutLayout,
        bufferLayout: KBufferLayout
    ) -> String {
        let hasWorldPosition: Bool = {
            guard case .compound(let layout) = inputLayout else { return false }
            return layout.items.contains { $0.name == "worldPosition" }
        }()
        let hasSharedUniforms = bufferLayout.bufferLayoutBindings.contains { $0.type == .uniformsShared }

        guard hasWorldPosition && hasSharedUniforms else { return "" }

        return
"""
    float3 nearCameraOffset = fragmentIn.worldPosition - uniformsShared.cameraPosition;
    float nearCameraFade = smoothstep(0.5625, 16.0, dot(nearCameraOffset, nearCameraOffset));
    fragmentColor.a *= nearCameraFade;

"""
    }

    static func generateShaderCode(
        functionName: String,
        shaderVariant: FragmentFunctionVariant,
        fragmentCode: String,
        fragmentLightingCode: String?,
        fragmentTransparencyCode: String?,
        fragmentOutputCode: String,
        inputLayout: KInOutLayout,
        outputLayout: KInOutLayout,
        bufferLayout: KBufferLayout,
        textureLayout: KTextureLayout,
        materialLayout: KMaterialLayout,
        attachmentLayout: KAttachmentLayout,
        isInstanced: Bool
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
        } + (textureLayout.textureLayoutBindings + materialLayout.textureLayoutBindings).flatMap { textureLayoutBinding in
            let textureParameter = "\(textureLayoutBinding.type.dataType)<\(textureLayoutBinding.type.primitiveType), access::\(textureLayoutBinding.accessType)> \(textureLayoutBinding.type) [[texture(\(textureLayoutBinding.index))]]"
            let samplerParameter = "sampler \(textureLayoutBinding.type)Sampler [[sampler(\(textureLayoutBinding.index))]]"
            return [textureParameter, samplerParameter]
        }

        return
"""
fragment \(outputLayout.name) \(functionName)(
    \(inputLayout.name) fragmentIn [[stage_in]],
    \(functionParameters.joined(separator: ",\n    "))
)
{
    \(isInstanced ? "DrawObjectUniforms uniformsObject = instancedObjectUniforms[fragmentIn.instanceId];" : "")
    \(outputLayout.name) fragmentOut;
\(fragmentCode)
\(shaderVariant.isGBuffer ? "" : fragmentLightingCode ?? "")
\(shaderVariant.isTransparency ? Self.generateNearCameraFadeCode(inputLayout: inputLayout, bufferLayout: bufferLayout) : "")
\(shaderVariant.isTransparency ? fragmentTransparencyCode ?? "" : "")
\(fragmentOutputCode)
    return fragmentOut;
}
"""
    }
}
