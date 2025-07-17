import Metal

struct ComputePipelineState {
    let computeFunction: ComputeShaderFunction
    let pipelineState: MTLComputePipelineState
}

public class ComputePipeline {
    let name: String
    let computeVariants: [ComputeFunctionVariant: ComputePipelineState]

    init(
        device: MTLDevice,
        library: MTLLibrary,
        name: String,
        computeFunctionGroup: ComputeShaderFunctionGroup,
        computeVariants: [ComputeFunctionVariant]
    ) throws {
        self.name = name
        self.computeVariants = try computeVariants
            .reduce(into: [:])
        { result, variant in
            return result[variant] = try Self.createPipelineVariant(
                device: device,
                library: library,
                shaderName: name,
                computeVariant: variant,
                computeFunctionGroup: computeFunctionGroup)
        }
    }

    static func createPipelineVariant(
        device: MTLDevice,
        library: MTLLibrary,
        shaderName: String,
        computeVariant: ComputeFunctionVariant,
        computeFunctionGroup: ComputeShaderFunctionGroup
    ) throws -> ComputePipelineState {
        let computeFunction = computeFunctionGroup.getShaderFunction(computeVariant)
        let computeShaderFunction = library.makeFunction(name: computeFunction.functionName)!
        let pipelineState = try! device.makeComputePipelineState(function: computeShaderFunction)

        return ComputePipelineState(
            computeFunction: computeFunction,
            pipelineState: pipelineState)
    }

    func execute(
        commandEncoder: MTLComputeCommandEncoder,
        dataBindings: [KBufferBindingType:GPUData] = [:],
        textureBindings: [KTextureBindingType:GPUTexture],
        computeVariant: ComputeFunctionVariant
    ) {
        let shaderFunctions = computeVariants[computeVariant]

        if let supportedShaderFunctions = shaderFunctions {
            commandEncoder.setComputePipelineState(supportedShaderFunctions.pipelineState)
            let computeFunction = supportedShaderFunctions.computeFunction

            for binding in computeFunction.bufferLayout.bufferLayoutBindings {
                if let data = dataBindings[binding.type] {
                    switch data {
                    case let .buffer(buffer):
                        commandEncoder.setBuffer(buffer.buffer, offset: buffer.offset, index: binding.index)
                    case let .wrapper(wrapper):
                        var data = wrapper.data
                        commandEncoder.setBytes(&data, length: wrapper.length, index: binding.index)
                    }
                }
            }
            for binding in computeFunction.textureLayout.textureLayoutBindings {
                if let textureData = textureBindings[binding.type] {
                    switch textureData {
                    case let .texture(textureData):
                        let texture = textureData.texture
                        let sampler = textureData.sampler
                        commandEncoder.setTexture(texture, index: binding.index)
                        commandEncoder.setSamplerState(sampler, index: binding.index)
                    case let .textureArray(textureArray):
                        let sampler = textureArray.sampler
                        commandEncoder.setTexture(textureArray.textureArray, index: binding.index)
                        commandEncoder.setSamplerState(sampler, index: binding.index)
                    case let .arrayOfTexture(textureArray):
                        let sampler = textureArray.sampler
                        for (offset, texture) in textureArray.texture.enumerated() {
                            commandEncoder.setTexture(texture, index: binding.index + offset)
                            commandEncoder.setSamplerState(sampler, index: binding.index + offset)
                        }
                    }
                }
            }
        }
    }
}
