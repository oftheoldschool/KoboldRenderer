import Metal

class RenderStageWriteOutput {
    func render(
        commandBuffer: MTLCommandBuffer,
        outputRenderPassDescriptor: MTLRenderPassDescriptor,
        shaderLibrary: ShaderLibrary,
        outputTexture: TextureData
    ) {
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: outputRenderPassDescriptor
        ) {
            commandEncoder.setCullMode(.back)
            commandEncoder.setFrontFacing(.counterClockwise)

            shaderLibrary.pipelines["PassThrough"]!.draw(
                commandEncoder: commandEncoder,
                textureBindings: [.texturePassThrough: .texture(outputTexture)],
                renderTarget: .colorPlusDepth,
                msaaEnabled: false,
                hasTransparency: false,
                model: nil)

            commandEncoder.endEncoding()
        }
    }
}
