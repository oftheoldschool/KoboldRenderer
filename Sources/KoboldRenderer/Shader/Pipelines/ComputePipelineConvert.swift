import Metal

public class ComputePipelineConvert: ComputePipeline {
    func convert(
        commandBuffer: MTLCommandBuffer,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture
    ) {
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        let textureData: [KTextureBindingType: GPUTexture] = [
            .textureComputeInput: .texture(TextureData(texture: inputTexture, sampler: nil)),
            .textureComputeOutput: .texture(TextureData(texture: outputTexture, sampler: nil)),
        ]
        self.execute(
            commandEncoder: computeEncoder,
            textureBindings: textureData,
            computeVariant: .color)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (outputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (outputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
    }
}
