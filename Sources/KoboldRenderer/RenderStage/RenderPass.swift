import Metal

class RenderPass {
    let depthStateYesTestYesWrite: MTLDepthStencilState
    let depthStateYesTestNoWrite: MTLDepthStencilState
    let depthStateNoTestNoWrite: MTLDepthStencilState

    init(device: MTLDevice) {
        let depthStencilStateEnabledDescriptor = MTLDepthStencilDescriptor()
        depthStencilStateEnabledDescriptor.depthCompareFunction = .greater
        depthStencilStateEnabledDescriptor.isDepthWriteEnabled = true
        self.depthStateYesTestYesWrite = device.makeDepthStencilState(descriptor: depthStencilStateEnabledDescriptor)!

        let depthStencilStateDisabledDescriptor = MTLDepthStencilDescriptor()
        depthStencilStateDisabledDescriptor.depthCompareFunction = .always
        depthStencilStateDisabledDescriptor.isDepthWriteEnabled = false
        self.depthStateNoTestNoWrite = device.makeDepthStencilState(descriptor: depthStencilStateDisabledDescriptor)!

        let depthStencilStateTestNoWriteDescriptor = MTLDepthStencilDescriptor()
        depthStencilStateTestNoWriteDescriptor.depthCompareFunction = .greater
        depthStencilStateTestNoWriteDescriptor.isDepthWriteEnabled = false
        self.depthStateYesTestNoWrite = device.makeDepthStencilState(descriptor: depthStencilStateTestNoWriteDescriptor)!
    }

    func render(
        shaderLibrary: ShaderLibrary,
        modelManager: ModelManager,
        commandBuffer: MTLCommandBuffer,
        outputRenderPassDescriptor: MTLRenderPassDescriptor,
        drawDataList: [DrawData],
        dataBindings: [KBufferBindingType: GPUData],
        textureBindings: [KTextureBindingType: GPUTexture] = [:],
        currentFrame: Int,
        renderTarget: ShaderRenderTarget,
        isShadowPass: Bool = false,
        isTransparencyPass: Bool = false,
        msaaEnabled: Bool = false,
        rendererSettings: KRRendererSettings
    ) {
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: outputRenderPassDescriptor) {
            if isTransparencyPass {
                commandEncoder.setCullMode(.none)
            } else {
                commandEncoder.setCullMode(.back)
            }

            if isShadowPass {
                commandEncoder.setDepthBias(
                    -rendererSettings.depthBias,
                    slopeScale: -rendererSettings.depthSlopeScale,
                    clamp: rendererSettings.depthClamp
                )

                let viewport = MTLViewport(
                    originX: 0,
                    originY: 0,
                    width: Double(RenderStageShadow.defaultBaseTextureSize),
                    height: Double(RenderStageShadow.defaultBaseTextureSize),
                    znear: 0.0,
                    zfar: 1.0)
                commandEncoder.setViewport(viewport)
            }

            for drawData in drawDataList {
                commandEncoder.setFrontFacing(.counterClockwise)

                if isTransparencyPass {
                    commandEncoder.setDepthStencilState(depthStateYesTestNoWrite)
                } else if drawData.drawFirst && !isShadowPass {
                    commandEncoder.setDepthStencilState(depthStateNoTestNoWrite)
                } else {
                    commandEncoder.setDepthStencilState(depthStateYesTestYesWrite)
                }

                let pipeline = shaderLibrary[drawData.pipeline]!
                pipeline.draw(
                    commandEncoder: commandEncoder,
                    dataBindings: dataBindings + drawData.perObjectBufferBindings,
                    textureBindings: textureBindings,
                    instanceCount: drawData.instanceCount,
                    renderTarget: renderTarget,
                    msaaEnabled: msaaEnabled,
                    hasTransparency: isTransparencyPass,
                    model: modelManager.models[drawData.model])
            }
            commandEncoder.endEncoding()
        }
    }
}
