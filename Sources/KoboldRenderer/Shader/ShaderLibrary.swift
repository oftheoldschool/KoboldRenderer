import Metal

enum ShaderRenderTarget {
    case colorPlusDepth
    case depth
    case colorPlusBrightnessPlusDepth
    case gbuffer
}

struct ShaderVariant: Hashable {
    let renderTarget: ShaderRenderTarget
    let shaderOptions: ShaderOptions

    func expand() -> [ShaderVariant] {
        let variants: [ShaderVariant] = [self]
        let enabledOptions = ShaderOptions.allCases.filter { self.shaderOptions.contains($0) }

        if enabledOptions.isEmpty {
            return variants
        }

        var result: [ShaderOptions] = [ShaderOptions()]

        for option in enabledOptions {
            let newVariants = result.map { $0.union(option) }
            result += newVariants
        }

        return result.map { ShaderVariant(renderTarget: self.renderTarget, shaderOptions: $0) }
    }

}

struct ShaderOptions: OptionSet, Hashable, CustomStringConvertible, CaseIterable {
    let rawValue: Int

    static let msaa = ShaderOptions(rawValue: 1 << 0)
    static let instanced = ShaderOptions(rawValue: 1 << 1)
    static let animated = ShaderOptions(rawValue: 1 << 2)
    static let transparency = ShaderOptions(rawValue: 1 << 3)
    static let allCases: [ShaderOptions] = [.msaa, .instanced, .animated, .transparency]

    var description: String {
        var options: [String] = []

        if contains(.msaa) { options.append("msaa") }
        if contains(.instanced) { options.append("instanced") }
        if contains(.animated) { options.append("animated") }
        if contains(.transparency) { options.append("transparency") }

        return options.isEmpty ? "None" : options.joined(separator: ", ")
    }
}

public class ShaderLibrary {
    public let pipelines: [String: RenderPipeline]
    let computePipelines: [String: ComputePipeline]

    public subscript(name: String) -> RenderPipeline? {
        return pipelines[name]
    }

    public func getComputePipeline<T: ComputePipeline>(_ name: String) -> T {
        return computePipelines[name]! as! T
    }

    init(
        device: MTLDevice,
        layoutLibrary: LayoutLibrary,
        renderingMode: KRRenderingMode,
        shadowTextureNumCascades: Int,
        shadowBaseTextureSize: Int,
        msaaSampleCount: Int,
        additionalRenderPipelineDefinitions: [RenderPipelineDefinition],
        additionalShaderCode: [String],
        additionalVertexFunctionTemplates: [VertexShaderFunctionTemplate.Type],
        additionalFragmentFunctionTemplates: [FragmentShaderFunctionTemplate.Type],
        additionalComputeFunctionTemplates: [ComputeShaderFunctionTemplate.Type]
    ) throws {
        let vertexFunctionTemplates: [VertexShaderFunctionTemplate.Type] = [
            VertexShaderFunctionTemplateBasic.self,
            VertexShaderFunctionTemplateAnimation.self,
            VertexShaderFunctionTemplateSkySphere.self,
            VertexShaderFunctionTemplatePassThrough.self,
        ] + additionalVertexFunctionTemplates

        let fragmentFunctionTemplates: [FragmentShaderFunctionTemplate.Type] = [
            FragmentShaderFunctionTemplateColor.self,
            FragmentShaderFunctionTemplateTexture.self,
            FragmentShaderFunctionTemplateCubeTexture.self,
            FragmentShaderFunctionTemplatePassThrough.self,
        ] + additionalFragmentFunctionTemplates

        let computeFunctionTemplates: [ComputeShaderFunctionTemplate.Type] = ([
            ComputeShaderFunctionTemplateCombine.self,
            ComputeShaderFunctionTemplateConvert.self,
        ] + (renderingMode == .deferred ? [ComputeShaderFunctionTemplateGBufferCombine.self] : [])
                                                                              + additionalComputeFunctionTemplates)

        // todo: we can probably do away with this too
        // some time later... can we though?
        let variableMap = [
            "CASCADED_SHADOW_NUM_CASCADES": "\(shadowTextureNumCascades)",
            "CASCADED_SHADOW_BASE_SIZE": "\(shadowBaseTextureSize)",
        ]

        let commonShader = ShaderCodeCommon.getShaderCode(
            includeHeader: true,
            variableMap: variableMap,
            vertexLayouts: layoutLibrary.vertexLayouts.map { $0.value },
            structLayouts: layoutLibrary.uniformLayouts.values + layoutLibrary.inOutLayouts.compactMap { item in
                if case let .compound(layout) = item.value {
                    return layout
                }
                return nil
            })

        let vertexFunctions: [String: VertexShaderFunctionGroup] = vertexFunctionTemplates.map { template in
            template.createFunctionGroup(layoutLibrary: layoutLibrary, variableMap: variableMap)
        }.reduce(into: [:]) { result, element in
            result[element.functionName] = element
        }

        let fragmentFunctions = fragmentFunctionTemplates.map { template in
            template.createFunctionGroup(
                layoutLibrary: layoutLibrary,
                variableMap: variableMap,
                renderingMode: renderingMode)
        }.reduce(into: [:]) { result, element in
            result[element.functionName] = element
        }

        let computeFunctions: [String: ComputeShaderFunctionGroup] = computeFunctionTemplates.map { template in
            template.createFunctionGroup(layoutLibrary: layoutLibrary, variableMap: variableMap)
        }.reduce(into: [:]) { result, element in
            result[element.functionName] = element
        }

        let allVertexFunctions = vertexFunctions.values.flatMap { $0.getAllShaders().map { $0.shaderCode } }
        let allFragmentFunctions = fragmentFunctions.values.flatMap { $0.getAllShaders().map { $0.shaderCode } }
        let allComputeFunctions = computeFunctions.values.flatMap { $0.getAllShaders().map { $0.shaderCode } }

        let shaderCode = (
            [
                commonShader,
                ShaderCodeNoise.getShaderCode(variableMap: variableMap),
                ShaderCodeShadow.getShaderCode(variableMap: variableMap),
                ShaderCodeLighting.getShaderCode(variableMap: variableMap),
                ShaderCodeColor.getShaderCode(variableMap: variableMap),
            ]
            + additionalShaderCode
            + allVertexFunctions
            + allFragmentFunctions
            + allComputeFunctions
        ).joined(separator: "\n\n")

        print(shaderCode)

        let library = try device.makeLibrary(
            source: shaderCode,
            options: nil)

        self.computePipelines = (([
            try! ComputePipelineConvert(
                device: device,
                library: library,
                name: "convert",
                computeFunctionGroup: computeFunctions["convertRGBA32FloatToBGRA8Unorm"]!,
                computeVariants: [.color]),
            try! ComputePipelineCombine(
                device: device,
                library: library,
                name: "computeShaderCombine",
                computeFunctionGroup: computeFunctions["computeShaderCombine"]!,
                computeVariants: [.color, .colorPlusBloom]),
        ] as [ComputePipeline]) + (renderingMode == .deferred ? [
            try! ComputePipelineGBufferCombine(
                device: device,
                library: library,
                name: "GBufferCombine",
                computeFunctionGroup: computeFunctions["computeShaderGBufferCombine"]!,
                computeVariants: [.color, .colorPlusBloom]),
        ] : [])).reduce(into: [:]) { result, element in
            result[element.name] = element
        }

        self.pipelines = ([
            try! RenderPipeline(
                device: device,
                library: library,
                name: "TexturedAnimated",
                vertexFunction: vertexFunctions["fullVertex"]!,
                fragmentFunction: fragmentFunctions["texturedFragment"]!,
                shaderVariants: Self.filterVariants(
                    [
                        ShaderVariant(renderTarget: .colorPlusDepth, shaderOptions: [.instanced, .msaa, .animated]),
                        ShaderVariant(renderTarget: .colorPlusBrightnessPlusDepth, shaderOptions: [.instanced, .msaa, .animated]),
                        ShaderVariant(renderTarget: .gbuffer, shaderOptions: [.instanced, .animated]),
                        ShaderVariant(renderTarget: .depth, shaderOptions: [.instanced, .animated]),
                    ],
                    renderingMode: renderingMode),
                msaaSampleCount: msaaSampleCount),
            try! RenderPipeline(
                device: device,
                library: library,
                name: "Textured",
                vertexFunction: vertexFunctions["basicVertex"]!,
                fragmentFunction: fragmentFunctions["texturedFragment"]!,
                shaderVariants: Self.filterVariants(
                    [
                        ShaderVariant(renderTarget: .colorPlusDepth, shaderOptions: [.instanced, .msaa]),
                        ShaderVariant(renderTarget: .colorPlusBrightnessPlusDepth, shaderOptions: [.instanced, .msaa]),
                        ShaderVariant(renderTarget: .gbuffer, shaderOptions: [.instanced]),
                        ShaderVariant(renderTarget: .depth, shaderOptions: [.instanced]),
                    ],
                    renderingMode: renderingMode),
                msaaSampleCount: msaaSampleCount),
            try! RenderPipeline(
                device: device,
                library: library,
                name: "Basic",
                vertexFunction: vertexFunctions["basicVertex"]!,
                fragmentFunction: fragmentFunctions["colorFragment"]!,
                shaderVariants: Self.filterVariants(
                    [
                        ShaderVariant(renderTarget: .colorPlusDepth, shaderOptions: [.instanced, .msaa, .transparency]),
                        ShaderVariant(renderTarget: .colorPlusBrightnessPlusDepth, shaderOptions: [.instanced, .msaa, .transparency]),
                        ShaderVariant(renderTarget: .gbuffer, shaderOptions: [.instanced]),
                        ShaderVariant(renderTarget: .depth, shaderOptions: [.instanced]),
                    ],
                    renderingMode: renderingMode),
                msaaSampleCount: msaaSampleCount),
            try! RenderPipeline(
                device: device,
                library: library,
                name: "SkyBox",
                vertexFunction: vertexFunctions["skyboxVertex"]!,
                fragmentFunction: fragmentFunctions["cubeTexturedFragment"]!,
                shaderVariants: Self.filterVariants(
                    [
                        ShaderVariant(renderTarget: .colorPlusDepth, shaderOptions: [.msaa]),
                        ShaderVariant(renderTarget: .colorPlusBrightnessPlusDepth, shaderOptions: [.msaa]),
                        ShaderVariant(renderTarget: .gbuffer, shaderOptions: []),
                    ],
                    renderingMode: renderingMode),
                msaaSampleCount: msaaSampleCount),
            try! RenderPipeline(
                device: device,
                library: library,
                name: "PassThrough",
                vertexFunction: vertexFunctions["passThroughVertex"]!,
                fragmentFunction: fragmentFunctions["passThroughFragment"]!,
                shaderVariants: [
                    ShaderVariant(renderTarget: .colorPlusDepth, shaderOptions: []),
                ],
                msaaSampleCount: msaaSampleCount
            ),
            try! RenderPipeline(
                device: device,
                library: library,
                name: "DebugBoundingBox",
                vertexFunction: vertexFunctions["basicVertex"]!,
                fragmentFunction: fragmentFunctions["colorFragment"]!,
                shaderVariants: Self.filterVariants(
                    [
                        ShaderVariant(renderTarget: .colorPlusDepth, shaderOptions: [.instanced, .msaa]),
                        ShaderVariant(renderTarget: .colorPlusBrightnessPlusDepth, shaderOptions: [.instanced, .msaa]),
                        ShaderVariant(renderTarget: .gbuffer, shaderOptions: [.instanced]),
                    ],
                    renderingMode: renderingMode),
                msaaSampleCount: msaaSampleCount
            ),
        ] + additionalRenderPipelineDefinitions.map { pipelineDefinition in
            var supportedTargets: [ShaderRenderTarget] = [
                ShaderRenderTarget.colorPlusDepth,
                ShaderRenderTarget.gbuffer,
            ]
            if pipelineDefinition.supportsBloom {
                supportedTargets.append(ShaderRenderTarget.colorPlusBrightnessPlusDepth)
            }
            if pipelineDefinition.supportsDepth {
                supportedTargets.append(ShaderRenderTarget.depth)
            }
            return try! RenderPipeline(
                device: device,
                library: library,
                name: pipelineDefinition.name,
                vertexFunction: vertexFunctions[pipelineDefinition.vertexFunctionName]!,
                fragmentFunction: fragmentFunctions[pipelineDefinition.fragmentFunctionName]!,
                shaderVariants: Self.filterVariants(
                    supportedTargets.map { target in
                        var shaderOptions: ShaderOptions = []
                        if target != .gbuffer {
                            shaderOptions.insert(.msaa)
                            if pipelineDefinition.supportsTransparency {
                                shaderOptions.insert(.transparency)
                            }
                        }
                        if pipelineDefinition.supportsAnimation {
                            shaderOptions.insert(.animated)
                        }
                        if pipelineDefinition.supportsInstancing {
                            shaderOptions.insert(.instanced)
                        }
                        return ShaderVariant(renderTarget: target, shaderOptions: shaderOptions)
                    },
                    renderingMode: renderingMode,
                    supportsTransparency: pipelineDefinition.supportsTransparency),
                msaaSampleCount: msaaSampleCount)
        }).reduce(into: [:]) { result, element in
            result[element.name] = element
        }
    }

    private static func filterVariants(
        _ variants: [ShaderVariant],
        renderingMode: KRRenderingMode,
        supportsTransparency: Bool = false
    ) -> [ShaderVariant] {
        let filtered = variants.filter { variant in
            switch renderingMode {
            case .forward:
                return variant.renderTarget != .gbuffer
            case .deferred:
                switch variant.renderTarget {
                case .gbuffer, .depth:
                    return true
                case .colorPlusDepth, .colorPlusBrightnessPlusDepth:
                    return supportsTransparency || variant.shaderOptions.contains(.transparency)
                }
            }
        }

        return filtered.isEmpty ? variants : filtered
    }
}
