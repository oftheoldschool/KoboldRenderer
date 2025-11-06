import Metal
import simd

struct ForwardTextures {
    var msaaColorRenderTarget: MTLTexture?
    var msaaBloomRenderTarget: MTLTexture?
    var msaaDepthTarget: MTLTexture?
}

struct ForwardResources {
    let renderPassDescriptor: MTLRenderPassDescriptor
    let forwardTextures: ForwardTextures
}

class RenderStageOpaqueTechniqueForward: RenderStageOpaqueTechnique {
    var forwardResources: ForwardResources? = nil

    func resize(
        device: MTLDevice,
        outputDimensions: (width: Int, height: Int),
        rendererSettings: KRRendererSettings,
        outputTargets: RenderStageOpaqueOutput
    ) {
        self.forwardResources = Self.createForwardResources(
            device: device,
            outputDimension: outputDimensions,
            rendererSettings: rendererSettings,
            outputTargets: outputTargets)
    }

    func render(
        shaderLibrary: ShaderLibrary,
        dataBindings: [KBufferBindingType: GPUData],
        textureBindings: [KTextureBindingType: GPUTexture],
        rendererSettings: KRRendererSettings,
        renderPass: RenderPass,
        commandBuffer: MTLCommandBuffer,
        currentFrame: Int,
        elapsedTime: Float,
        camera: KRCamera,
        lightingData: LightingData,
        modelManager: ModelManager,
        materialsBuffer: GPUDataMultiBuffer,
        globalMaterialId: Int,
        globalLightingColor: SIMD3<Float>,
        lightsBuffer: GPUDataMultiBuffer,
        drawDataList: [DrawData],
        outputTargets: RenderStageOpaqueOutput
    ) {
        guard let resources = forwardResources else {
            return
        }

        renderPass.render(
            shaderLibrary: shaderLibrary,
            modelManager: modelManager,
            commandBuffer: commandBuffer,
            outputRenderPassDescriptor: resources.renderPassDescriptor,
            drawDataList: drawDataList
                .sorted(by: { $0.drawFirst && !$1.drawFirst }),
            dataBindings: dataBindings,
            textureBindings: textureBindings,
            currentFrame: currentFrame,
            renderTarget: rendererSettings.bloomEnabled ? .colorPlusBrightnessPlusDepth : .colorPlusDepth,
            msaaEnabled: rendererSettings.msaaEnabled,
            rendererSettings: rendererSettings)
    }

    static func createForwardResources(
        device: MTLDevice,
        outputDimension: (width: Int, height: Int),
        rendererSettings: KRRendererSettings,
        outputTargets: RenderStageOpaqueOutput
    ) -> ForwardResources? {
        let outputTarget: ForwardResources?

        let (width, height) = outputDimension

        let msaaSampleCount = rendererSettings.msaaEnabled ? rendererSettings.msaaSampleCount : 1

        let textures = ForwardTextures(
            msaaColorRenderTarget: rendererSettings.msaaEnabled ? Self.createMSAAColorRenderTexture(
                device: device,
                width: width,
                height: height,
                msaaSampleCount: msaaSampleCount) : nil,
            msaaBloomRenderTarget: (rendererSettings.msaaEnabled && rendererSettings.bloomEnabled) ? Self.createMSAABloomRenderTexture(
                device: device,
                width: width,
                height: height,
                msaaSampleCount: msaaSampleCount) : nil,
            msaaDepthTarget: rendererSettings.msaaEnabled ? Self.createDepthRenderTexture(
                device: device,
                width: width,
                height: height,
                msaaSampleCount: msaaSampleCount) : nil)

        let renderPassDescriptor = MTLRenderPassDescriptor()

        if rendererSettings.msaaEnabled {
            renderPassDescriptor.depthAttachment.texture = textures.msaaDepthTarget
            renderPassDescriptor.depthAttachment.resolveTexture = outputTargets.depth
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .multisampleResolve

            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(rendererSettings.clearColor)
            renderPassDescriptor.colorAttachments[0].texture = textures.msaaColorRenderTarget
            renderPassDescriptor.colorAttachments[0].resolveTexture = outputTargets.color
            if rendererSettings.bloomEnabled {
                renderPassDescriptor.colorAttachments[1].loadAction = .clear
                renderPassDescriptor.colorAttachments[1].storeAction = .multisampleResolve
                renderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor.black
                renderPassDescriptor.colorAttachments[1].texture = textures.msaaBloomRenderTarget
                renderPassDescriptor.colorAttachments[1].resolveTexture = outputTargets.brightness
            }
        } else {
            renderPassDescriptor.depthAttachment.texture = outputTargets.depth
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .store

            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(rendererSettings.clearColor)
            renderPassDescriptor.colorAttachments[0].texture = outputTargets.color
            if rendererSettings.bloomEnabled {
                renderPassDescriptor.colorAttachments[1].loadAction = .clear
                renderPassDescriptor.colorAttachments[1].storeAction = .store
                renderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor.black
                renderPassDescriptor.colorAttachments[1].texture = outputTargets.brightness
            }
        }

        outputTarget = ForwardResources(
            renderPassDescriptor: renderPassDescriptor,
            forwardTextures: textures)
        return outputTarget
    }

    static func createDepthRenderTexture(
        device: MTLDevice,
        width: Int,
        height: Int,
        msaaSampleCount: Int
    ) -> MTLTexture {
        let depthTextureDescriptor = MTLTextureDescriptor()
        depthTextureDescriptor.pixelFormat = .depth32Float
        depthTextureDescriptor.textureType = .type2DMultisample
        depthTextureDescriptor.sampleCount = msaaSampleCount
        depthTextureDescriptor.width = width
        depthTextureDescriptor.height = height
        depthTextureDescriptor.mipmapLevelCount = 1
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDescriptor.storageMode = .private
        let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
        depthTexture.label = "MSAA Depth Render Texture"
        return depthTexture
    }

    static func createMSAAColorRenderTexture(
        device: MTLDevice,
        width: Int,
        height: Int,
        msaaSampleCount: Int
    ) -> MTLTexture {
        let msaaTexDescriptor = MTLTextureDescriptor()
        msaaTexDescriptor.pixelFormat = .bgra8Unorm
        msaaTexDescriptor.textureType = .type2DMultisample
        msaaTexDescriptor.sampleCount = msaaSampleCount
        msaaTexDescriptor.width = width
        msaaTexDescriptor.height = height
        msaaTexDescriptor.mipmapLevelCount = 1
        msaaTexDescriptor.usage = [.renderTarget]
        msaaTexDescriptor.storageMode = .memoryless
        let msaaTexture = device.makeTexture(descriptor: msaaTexDescriptor)!
        msaaTexture.label = "MSAA Color Render Texture"
        return msaaTexture
    }

    static func createMSAABloomRenderTexture(
        device: MTLDevice,
        width: Int,
        height: Int,
        msaaSampleCount: Int
    ) -> MTLTexture {
        let msaaBloomTextureDescriptor = MTLTextureDescriptor()
        msaaBloomTextureDescriptor.width = width
        msaaBloomTextureDescriptor.height = height
        msaaBloomTextureDescriptor.textureType = .type2DMultisample
        msaaBloomTextureDescriptor.pixelFormat = .bgra8Unorm
        msaaBloomTextureDescriptor.mipmapLevelCount = 1
        msaaBloomTextureDescriptor.storageMode = .memoryless
        msaaBloomTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        msaaBloomTextureDescriptor.sampleCount = msaaSampleCount
        let msaaBloomTexture = device.makeTexture(descriptor: msaaBloomTextureDescriptor)!
        msaaBloomTexture.label = "MSAA Bloom Render Texture"
        return msaaBloomTexture
    }
}
