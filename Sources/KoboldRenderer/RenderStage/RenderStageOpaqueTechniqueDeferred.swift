import Metal
import simd

struct DeferredTextures {
    var normals: MTLTexture
    var albedos: MTLTexture
}

struct DeferredResources {
    let renderPassDescriptor: MTLRenderPassDescriptor
    let deferredTextures: DeferredTextures
}

class RenderStageOpaqueTechniqueDeferred: RenderStageOpaqueTechnique {
    var deferredResources: DeferredResources? = nil
    let computePipelineGBufferCombine: ComputePipelineGBufferCombine

    init(shaderLibrary: ShaderLibrary) {
        self.computePipelineGBufferCombine = shaderLibrary.getComputePipeline("gbufferCombine")
    }

    func resize(
        device: MTLDevice,
        outputDimensions: (width: Int, height: Int),
        rendererSettings: KRRendererSettings,
        outputTargets: RenderStageOpaqueOutput
    ) {
        self.deferredResources = Self.createDeferredResources(
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
        guard let resources = deferredResources else {
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
            renderTarget: .gbuffer,
            msaaEnabled: rendererSettings.msaaEnabled)

        let deferredTextures = resources.deferredTextures

        computePipelineGBufferCombine.combine(
            commandBuffer: commandBuffer,
            normalTexture: deferredTextures.normals,
            albedoTexture: deferredTextures.albedos,
            depthTexture: outputTargets.depth,
            outputTexture: outputTargets.color,
            bloomTexture: outputTargets.brightness,
            lightingData: lightingData,
            dataBindings: dataBindings,
            currentFrame: currentFrame)
    }

    static func createDeferredResources(
        device: MTLDevice,
        outputDimension: (width: Int, height: Int),
        rendererSettings: KRRendererSettings,
        outputTargets: RenderStageOpaqueOutput
    ) -> DeferredResources? {
        let deferredResources: DeferredResources?

        let (width, height) = outputDimension

        // todo: hardcoding antialiasing to off for now.
        // if enabling it, need to handle multi sample resolve with multi sample textures
        let msaaEnabled = rendererSettings.msaaEnabled && false
        let msaaSampleCount = msaaEnabled ? rendererSettings.msaaSampleCount : 1

        let gbuffer = DeferredTextures(
            normals: Self.createGBufferTexture(
                device: device,
                width: width,
                height: height,
                msaaSampleCount: msaaSampleCount,
                description: "Normals"),
            albedos: Self.createGBufferTexture(
                device: device,
                width: width,
                height: height,
                msaaSampleCount: msaaSampleCount,
                description: "Albedo"))

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.texture = outputTargets.depth

        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.black
        renderPassDescriptor.colorAttachments[0].texture = gbuffer.normals

        renderPassDescriptor.colorAttachments[1].loadAction = .clear
        renderPassDescriptor.colorAttachments[1].storeAction = .store
        renderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor.black
        renderPassDescriptor.colorAttachments[1].texture = gbuffer.albedos

        deferredResources = DeferredResources(
            renderPassDescriptor: renderPassDescriptor,
            deferredTextures: gbuffer)

        return deferredResources
    }

    static func createGBufferTexture(
        device: MTLDevice,
        width: Int,
        height: Int,
        msaaSampleCount: Int,
        description: String
    ) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba32Float
        if msaaSampleCount > 1 {
            textureDescriptor.textureType = .type2DMultisample
            textureDescriptor.sampleCount = msaaSampleCount
        } else {
            textureDescriptor.textureType = .type2D
        }
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.mipmapLevelCount = 1
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .private
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        texture.label = "GBuffer \(description) Texture"
        return texture
    }
}
