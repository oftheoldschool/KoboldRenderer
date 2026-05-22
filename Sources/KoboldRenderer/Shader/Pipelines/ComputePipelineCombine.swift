import Metal

public class ComputePipelineCombine: ComputePipeline {
    func combine(
        commandBuffer: MTLCommandBuffer,
        opaqueOutput: RenderStageOpaqueOutput,
        transparentOutput: RenderStageTransparentOutput,
        outputTexture: MTLTexture,
        rendererSettings: KRRendererSettings
    ) {
        if let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            let textureBindings: [KTextureBindingType: GPUTexture] = [
                .textureComputeOutput: .texture(TextureData(texture: outputTexture, sampler: nil)),
                .textureCombineRevealage: .texture(TextureData(texture: transparentOutput.revealageTexture, sampler: nil)),
                .textureCombineColor: .texture(TextureData(texture: opaqueOutput.color, sampler: nil)),
                .textureCombineColorAlpha: .texture(TextureData(texture: transparentOutput.accumulationColor, sampler: nil)),
                .textureCombineOpaqueDepth: .texture(TextureData(texture: opaqueOutput.depth, sampler: nil)),
            ] + (opaqueOutput.brightness.map {
                [.textureCombineBrightness: .texture(TextureData(texture: $0, sampler: nil))]
            } ?? [:]) + (transparentOutput.accumulationBrightness.map {
                [.textureCombineBrightnessAlpha: .texture(TextureData(texture: $0, sampler: nil))]
            } ?? [:]) + (transparentOutput.revealageBlurredTexture.map {
                [.textureCombineRevealageBlurred: .texture(TextureData(texture: $0, sampler: nil))]
            } ?? [:])
            
            self.execute(
                commandEncoder: computeEncoder,
                dataBindings: [:],
                textureBindings: textureBindings,
                computeVariant: opaqueOutput.brightness == nil ? .color : .colorPlusBloom)
            
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
}
