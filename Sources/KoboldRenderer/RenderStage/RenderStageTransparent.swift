import Metal
import MetalPerformanceShaders

struct RenderStageTransparentOutput {
    var accumulationColor: MTLTexture
    var accumulationBrightness: MTLTexture?
    var revealageTexture: MTLTexture
    // Blurred copy of revealageTexture, used by the bloom combine pass to extend
    // transparent bloom into a halo. Only allocated when bloomEnabled.
    var revealageBlurredTexture: MTLTexture?
}

struct RenderStageTransparentResources {
    let output: RenderStageTransparentOutput
    let renderPassDescriptor: MTLRenderPassDescriptor
}

class RenderStageTransparent {
    var transparentResources: RenderStageTransparentResources?

    init(
        device: MTLDevice,
        shaderLibrary: ShaderLibrary,
        rendererSettings: KRRendererSettings
    ) {
        self.transparentResources = nil
    }

    func render(
        shaderLibrary: ShaderLibrary,
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
        occludersBuffer: GPUDataMultiBuffer,
        additionalBufferBindings: [KBufferBindingType: GPUData],
        additionalTextureBindings: [KTextureBindingType: GPUTexture] = [:],
        drawDataList: [DrawData],
        opaqueDepthTexture: MTLTexture
    ) -> RenderStageTransparentOutput? {
        guard let resources = transparentResources else {
            return nil
        }
        resources.renderPassDescriptor.depthAttachment.texture = opaqueDepthTexture

        let sharedUniforms = SharedUniforms(
            camera: camera,
            rendererSettings: rendererSettings,
            elapsedTime: elapsedTime,
            globalMaterialId: globalMaterialId)

        let lightingUniforms = LightingUniforms(
            globalLightingColor: globalLightingColor,
            shadowNormalBias: rendererSettings.shadowNormalBias,
            shadowBiasAngleFactor: rendererSettings.shadowBiasAngleFactor,
            shadowCascadeFactor: rendererSettings.shadowCascadeFactor,
            lightCount: UInt8(lightingData.lights.count),
            occluderCount: UInt8(lightingData.occluders.count),
            enableShadows: lightingData.enableShadows,
            enableLighting: lightingData.enableLighting)

        let dataBindings: [KBufferBindingType: GPUData] = [
            .uniformsShared: .wrapper(GPUDataWrapper(sharedUniforms)),
            .uniformsLights: .buffer(lightsBuffer[currentFrame]),
            .uniformsOccluders: .buffer(occludersBuffer[currentFrame]),
            .uniformsLighting: .wrapper(GPUDataWrapper(lightingUniforms)),
            .uniformsCascadeFrustumLimitsClipSpace: .wrapper(GPUDataWrapper(lightingData.cascadedShadowMap.cascadeFrustumLimitsClipSpace)),
            .uniformsLightSpaceVolumes: .wrapper(GPUDataWrapper(lightingData.cascadedShadowMap.lightVolumeViewProjections)),
            .materials: .buffer(materialsBuffer[currentFrame]),
        ] + additionalBufferBindings

        let textureBindings: [KTextureBindingType: GPUTexture] = [
            .textureArrayCascadedShadowMap: .textureArray(
                TextureArrayData(
                    textureArray: lightingData.cascadedShadowMap.shadowTextureArray,
                    sampler: lightingData.cascadedShadowMap.shadowTextureSampler)),
        ] + additionalTextureBindings

        renderPass.render(
            shaderLibrary: shaderLibrary,
            modelManager: modelManager,
            commandBuffer: commandBuffer,
            outputRenderPassDescriptor: resources.renderPassDescriptor,
            drawDataList: drawDataList,
            dataBindings: dataBindings,
            textureBindings: textureBindings,
            currentFrame: currentFrame,
            renderTarget: rendererSettings.bloomEnabled ? .colorPlusBrightnessPlusDepth : .colorPlusDepth,
            isTransparencyPass: true,
            msaaEnabled: false, // todo: hardcode msaa off since maintaining multiple transparency targets will be very expensive
            rendererSettings: rendererSettings
        )

        return resources.output
    }

    func resize(
        device: MTLDevice,
        outputDimensions: (width: Int, height: Int),
        rendererSettings: KRRendererSettings
    ) {
        self.transparentResources = Self.createTransparentResources(
            device: device,
            outputDimensions: outputDimensions,
            rendererSettings: rendererSettings)
    }


    static func createTransparentResources(
        device: MTLDevice,
        outputDimensions: (width: Int, height: Int),
        rendererSettings: KRRendererSettings
    ) -> RenderStageTransparentResources? {
        let (width, height) = outputDimensions
        let transparencyOutput = RenderStageTransparentOutput(
            accumulationColor: Self.createAccumulationTexture(
                device: device,
                width: width,
                height: height),
            accumulationBrightness: Self.createAccumulationTexture(
                device: device,
                width: width,
                height: height),
            revealageTexture: Self.createRevealageTexture(
                device: device,
                width: width,
                height: height,
                allowShaderWrite: false),
            revealageBlurredTexture: rendererSettings.bloomEnabled
                ? Self.createRevealageTexture(
                    device: device,
                    width: width,
                    height: height,
                    allowShaderWrite: true)
                : nil
        )

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.depthAttachment.loadAction = .load
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.clearDepth = 1
        // depth texture must be set when available at runtime

        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.white
        renderPassDescriptor.colorAttachments[0].texture = transparencyOutput.revealageTexture

        renderPassDescriptor.colorAttachments[1].loadAction = .clear
        renderPassDescriptor.colorAttachments[1].storeAction = .store
        renderPassDescriptor.colorAttachments[1].clearColor = MTLClearColor.black
        renderPassDescriptor.colorAttachments[1].texture = transparencyOutput.accumulationColor

        if rendererSettings.bloomEnabled {
            renderPassDescriptor.colorAttachments[2].loadAction = .clear
            renderPassDescriptor.colorAttachments[2].storeAction = .store
            renderPassDescriptor.colorAttachments[2].clearColor = MTLClearColor.black
            renderPassDescriptor.colorAttachments[2].texture = transparencyOutput.accumulationBrightness
        }

        return RenderStageTransparentResources(
            output: transparencyOutput,
            renderPassDescriptor: renderPassDescriptor)
    }


    static func createAccumulationTexture(
        device: MTLDevice,
        width: Int,
        height: Int
    ) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private

        let texture = device.makeTexture(descriptor: textureDescriptor)!
        texture.label = "Transparency Accumulation Texture"
        return texture
    }

    static func createRevealageTexture(
        device: MTLDevice,
        width: Int,
        height: Int,
        allowShaderWrite: Bool
    ) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r16Float,  // how to tie this up with the value in the render pass?
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = allowShaderWrite
            ? [.renderTarget, .shaderRead, .shaderWrite]
            : [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .private

        let texture = device.makeTexture(descriptor: textureDescriptor)!
        texture.label = allowShaderWrite
            ? "Transparency Revealage Blurred Texture"
            : "Transparency Revealage Texture"
        return texture
    }

    static func createTransparencyBloomTexture(
        device: MTLDevice,
        width: Int,
        height: Int
    ) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .private

        let texture = device.makeTexture(descriptor: textureDescriptor)!
        texture.label = "Transparency Bloom Texture"
        return texture
    }
}
