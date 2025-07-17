import Metal

enum PipelineError: Error {
    case mismatchError(String)
}

struct PipelineConfiguration {
    let vertexFunction: VertexShaderFunction?
    let fragmentFunction: FragmentShaderFunction?
    let pipelineState: MTLRenderPipelineState
}

public class RenderPipeline {
    let name: String
    let shaderVariants: [ShaderVariant: PipelineConfiguration]

    init(
        device: MTLDevice,
        library: MTLLibrary,
        name: String,
        vertexFunction: VertexShaderFunctionGroup,
        fragmentFunction: FragmentShaderFunctionGroup,
        shaderVariants: [ShaderVariant],
        msaaSampleCount: Int
    ) throws {
        self.name = name
        self.shaderVariants = try shaderVariants
            .flatMap { $0.expand() }
            .reduce(into: [:])
        { result, variant in
            return result[variant] = try Self.createPipelineConfiguration(
                device: device,
                library: library,
                shaderName: name,
                shaderVariant: variant,
                vertexFunctionGroup: vertexFunction,
                fragmentFunctionGroup: fragmentFunction,
                msaaSampleCount: msaaSampleCount)
        }
    }

    static func createPipelineConfiguration(
        device: MTLDevice,
        library: MTLLibrary,
        shaderName: String,
        shaderVariant: ShaderVariant,
        vertexFunctionGroup: VertexShaderFunctionGroup,
        fragmentFunctionGroup: FragmentShaderFunctionGroup,
        msaaSampleCount: Int
    ) throws -> PipelineConfiguration {
        let shaderRenderTarget = shaderVariant.renderTarget
        let shaderOptions = shaderVariant.shaderOptions

        let vertexVariant: VertexFunctionVariant = switch shaderRenderTarget {
        case .depth: shaderOptions.contains(.instanced)
            ? (shaderOptions.contains(.animated) ? .instancedAnimatedShadow : .instancedShadow)
            : (shaderOptions.contains(.animated) ? .singleAnimatedShadow : .singleShadow)
        default: shaderOptions.contains(.instanced)
            ? (shaderOptions.contains(.animated) ? .instancedAnimated : .instanced)
            : (shaderOptions.contains(.animated) ? .singleAnimated : .single)
        }
        let fragmentVariant: FragmentFunctionVariant? = switch shaderRenderTarget {
        case .gbuffer:
            shaderOptions.contains(.instanced)
            ? .instancedGBuffer
            : .gbuffer
        case .colorPlusBrightnessPlusDepth:
            shaderOptions.contains(.instanced)
            ? shaderOptions.contains(.transparency)
                ? .instancedColorAlphaPlusBrightness
                : .instancedColorPlusBrightness
            : shaderOptions.contains(.transparency)
                ? .colorAlphaPlusBrightness
                : .colorPlusBrightness
        case .colorPlusDepth:
            shaderOptions.contains(.instanced)
            ? shaderOptions.contains(.transparency)
                ? .instancedColorAlpha
                : .instancedColor
            : shaderOptions.contains(.transparency)
                ? .colorAlpha
                : .color
        case .depth: nil
        }

        let vertexFunction = vertexFunctionGroup.getShaderFunction(vertexVariant)
        let fragmentFunction = fragmentVariant.flatMap { fragmentFunctionGroup.getShaderFunction($0) }

        let attachmentLayout = fragmentFunction?.attachmentLayout ?? vertexFunction.attachmentLayout!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "\(shaderName) - \(shaderRenderTarget) - \(shaderOptions)"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexFunction.functionName)!

        if let fragmentFunction = fragmentFunction {
            if vertexFunction.outputLayout != fragmentFunction.inputLayout {
                throw PipelineError.mismatchError("Vertex function output layout did not match Fragment function input layout")
            }
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentFunction.functionName)!
        }

        if shaderOptions.contains(.msaa) {
            pipelineDescriptor.rasterSampleCount = msaaSampleCount
        }

        let vertexDescriptor = MTLVertexDescriptor()
        if let vertexLayout = vertexFunction.vertexLayout {
            for (index, attribute) in vertexLayout.attributes.enumerated() {
                let attributeDescriptor = MTLVertexAttributeDescriptor()
                attributeDescriptor.format = attribute.type.toMTLVertexFormat()
                attributeDescriptor.offset = attribute.offset
                attributeDescriptor.bufferIndex = attribute.binding.index
                vertexDescriptor.attributes[index] = attributeDescriptor

                let vertexBufferLayoutDescriptor = MTLVertexBufferLayoutDescriptor()
                vertexBufferLayoutDescriptor.stride = attribute.type.stride
                vertexDescriptor.layouts[index] = vertexBufferLayoutDescriptor
            }
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
        }

        for (index, attachment) in attachmentLayout.colorAttachments.enumerated() {
            pipelineDescriptor.colorAttachments[index] = attachment.toMTLRenderPipelineColorAttachmentDescriptor()
        }

        if let depthFormat = attachmentLayout.depthAttachment?.pixelFormat {
            pipelineDescriptor.depthAttachmentPixelFormat = depthFormat.toMTLPixelFormat()
        }

        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        return PipelineConfiguration(
            vertexFunction: vertexFunction,
            fragmentFunction: fragmentFunction,
            pipelineState: pipelineState)
    }

    func draw(
        commandEncoder: MTLRenderCommandEncoder,
        dataBindings: [KBufferBindingType: GPUData] = [:],
        textureBindings: [KTextureBindingType: GPUTexture],
        instanceCount: Int = 1,
        renderTarget: ShaderRenderTarget,
        msaaEnabled: Bool,
        hasTransparency: Bool,
        model: KModel?
    ) {
        var shaderOptions: ShaderOptions = []

        if instanceCount > 1 {
            shaderOptions.insert(.instanced)
        }

        if msaaEnabled {
            shaderOptions.insert(.msaa)
        }

        if hasTransparency {
            shaderOptions.insert(.transparency)
        }

        if dataBindings.keys.contains(.uniformsAnimationPose) {
            shaderOptions.insert(.animated)
        }

        let shaderVariant = ShaderVariant(
            renderTarget: renderTarget,
            shaderOptions: shaderOptions)
        let shaderFunctions = shaderVariants[shaderVariant]

        if let supportedShaderFunctions = shaderFunctions {
            commandEncoder.setRenderPipelineState(supportedShaderFunctions.pipelineState)
            let vertexFunction = supportedShaderFunctions.vertexFunction
            let fragmentFunction = supportedShaderFunctions.fragmentFunction

            if let vertexFunction = vertexFunction {
                for binding in vertexFunction.bufferLayout.bufferLayoutBindings {
                    if let data = dataBindings[binding.type] {
                        switch data {
                        case let .buffer(buffer):
                            commandEncoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: binding.index)
                        case let .wrapper(wrapper):
                            var data = wrapper.data
                            commandEncoder.setVertexBytes(&data, length: wrapper.length, index: binding.index)
                        }
                    }
                }
            }

            if let fragmentFunction = fragmentFunction {
                for binding in fragmentFunction.bufferLayout.bufferLayoutBindings {
                    if let data = dataBindings[binding.type] {
                        switch data {
                        case let .buffer(buffer):
                            commandEncoder.setFragmentBuffer(buffer.buffer, offset: buffer.offset, index: binding.index)
                        case let .wrapper(wrapper):
                            var data = wrapper.data
                            commandEncoder.setFragmentBytes(&data, length: wrapper.length, index: binding.index)
                        }
                    }
                }
                for binding in fragmentFunction.textureLayout.textureLayoutBindings {
                    if let textureData = textureBindings[binding.type] {
                        switch textureData {
                        case let .texture(textureData):
                            let texture = textureData.texture
                            let sampler = textureData.sampler
                            commandEncoder.setFragmentTexture(texture, index: binding.index)
                            commandEncoder.setFragmentSamplerState(sampler, index: binding.index)
                        case let .textureArray(textureArray):
                            let sampler = textureArray.sampler
                            commandEncoder.setFragmentTexture(textureArray.textureArray, index: binding.index)
                            commandEncoder.setFragmentSamplerState(sampler, index: binding.index)
                        case let .arrayOfTexture(textureArray):
                            let sampler = textureArray.sampler
                            for (offset, texture) in textureArray.texture.enumerated() {
                                commandEncoder.setFragmentTexture(texture, index: binding.index + offset)
                                commandEncoder.setFragmentSamplerState(sampler, index: binding.index + offset)
                            }
                        }
                    }
                }
            }

            if let model = model {
                for mesh in model.meshes {
                    if let vertexLayout = vertexFunction?.vertexLayout {
                        for attribute in vertexLayout.attributes {
                            if let buffer = mesh.attributes.buffers[attribute.binding.type] {
                                commandEncoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: attribute.binding.index)
                            }
                        }
                    }

                    if let fragment = fragmentFunction {
                        for binding in fragment.materialLayout.textureLayoutBindings {
                            if let textureName = mesh.textures[binding.type],
                               let textureData = model.textures[textureName]
                            {
                                let texture = textureData.texture
                                let sampler = textureData.sampler
                                commandEncoder.setFragmentTexture(texture, index: binding.index)
                                commandEncoder.setFragmentSamplerState(sampler, index: binding.index)
                            }
                        }
                    }

                    if let indices = mesh.indices,
                       let indexBuffer = indices.indexBuffer{
                        if instanceCount > 1 {
                            commandEncoder.drawIndexedPrimitives(
                                type: .triangle,
                                indexCount: indices.indexCount,
                                indexType: indices.indexBufferType.toMetalIndexType(),
                                indexBuffer: indexBuffer.buffer,
                                indexBufferOffset: indexBuffer.offset,
                                instanceCount: instanceCount)
                        } else {
                            commandEncoder.drawIndexedPrimitives(
                                type: .triangle,
                                indexCount: indices.indexCount,
                                indexType: indices.indexBufferType.toMetalIndexType(),
                                indexBuffer: indexBuffer.buffer,
                                indexBufferOffset: indexBuffer.offset)
                        }
                    } else {
                        commandEncoder.drawPrimitives(
                            type: .triangle,
                            vertexStart: 0,
                            vertexCount: mesh.attributes.vertexCount)
                    }
                }
            } else {
                // todo: 6 is for pass through. need a better way to indicate this than the mesh being nil
                commandEncoder.drawPrimitives(
                    type: .triangle,
                    vertexStart: 0,
                    vertexCount: 6)
            }
        }
    }
}
