import Metal

public class ComputePipelineGBufferCombine: ComputePipeline {
    func combine(
        commandBuffer: MTLCommandBuffer,
        normalTexture: MTLTexture,
        albedoTexture: MTLTexture,
        depthTexture: MTLTexture,
        outputTexture: MTLTexture,
        bloomTexture: MTLTexture? = nil,
        lightingData: LightingData,
        dataBindings: [KBufferBindingType: GPUData],
        currentFrame: Int
    ) {
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!

        let textureBindings: [KTextureBindingType: GPUTexture] = [
            .textureGBufferNormals: .texture(TextureData(texture: normalTexture, sampler: nil)),
            .textureGBufferAlbedos: .texture(TextureData(texture: albedoTexture, sampler: nil)),
            .textureGBufferDepth: .texture(TextureData(texture: depthTexture, sampler: nil)),
            .textureComputeOutput: .texture(TextureData(texture: outputTexture, sampler: nil)),
            .textureArrayCascadedShadowMap: .textureArray(
                TextureArrayData(
                    textureArray: lightingData.cascadedShadowMap.shadowTextureArray,
                    sampler: lightingData.cascadedShadowMap.shadowTextureSampler)),
        ] + (bloomTexture.map {
            [.textureComputeBloomOutput: .texture(TextureData(texture: $0, sampler: nil))]
        } ?? [:])

        self.execute(
            commandEncoder: computeEncoder,
            dataBindings: dataBindings,
            textureBindings: textureBindings,
            computeVariant: bloomTexture == nil ? .color : .colorPlusBloom)

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
