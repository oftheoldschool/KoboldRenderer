import Metal
import MetalPerformanceShaders

struct RenderStageOpaqueOutput {
    var color: MTLTexture
    var brightness: MTLTexture?
    var depth: MTLTexture
}

class RenderStageOpaque {
    private var opaqueTechnique: RenderStageOpaqueTechnique

    var renderTargets: RenderStageOpaqueOutput?

    init(
        device: MTLDevice,
        rendererSettings: KRRendererSettings,
        shaderLibrary: ShaderLibrary
    ) {
        self.renderTargets = nil
        self.opaqueTechnique = switch rendererSettings.renderingMode {
        case .forward: RenderStageOpaqueTechniqueForward()
        case .deferred: RenderStageOpaqueTechniqueDeferred(shaderLibrary: shaderLibrary)
        }
    }

    func applyChanges(
        rendererSettings: KRRendererSettings,
        shaderLibrary: ShaderLibrary
    ) {
        self.opaqueTechnique = switch rendererSettings.renderingMode {
        case .forward: RenderStageOpaqueTechniqueForward()
        case .deferred: RenderStageOpaqueTechniqueDeferred(shaderLibrary: shaderLibrary)
        }
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
        drawDataList: [DrawData]
    ) -> RenderStageOpaqueOutput? {
        guard let outputTargets = renderTargets else {
            return nil
        }

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
            .uniformsCascadeFrustumLimitsClipSpace: .wrapper(
                GPUDataWrapper(lightingData.cascadedShadowMap.cascadeFrustumLimitsClipSpace)),
            .uniformsLightSpaceVolumes: .wrapper(
                GPUDataWrapper(lightingData.cascadedShadowMap.lightVolumeViewProjections)),
            .materials: .buffer(materialsBuffer[currentFrame]),
        ]

        let textureBindings: [KTextureBindingType: GPUTexture] = [
            .textureArrayCascadedShadowMap: .textureArray(
                TextureArrayData(
                    textureArray: lightingData.cascadedShadowMap.shadowTextureArray,
                    sampler: lightingData.cascadedShadowMap.shadowTextureSampler)),
        ]

        opaqueTechnique.render(
            shaderLibrary: shaderLibrary,
            dataBindings: dataBindings,
            textureBindings: textureBindings,
            rendererSettings: rendererSettings,
            renderPass: renderPass,
            commandBuffer: commandBuffer,
            currentFrame: currentFrame,
            elapsedTime: elapsedTime,
            camera: camera,
            lightingData: lightingData,
            modelManager: modelManager,
            globalMaterialId: globalMaterialId,
            globalLightingColor: rendererSettings.globalLightingColor,
            drawDataList: drawDataList,
            outputTargets: outputTargets)
        return outputTargets
    }

    func resize(
        device: MTLDevice,
        outputDimensions: (width: Int, height: Int),
        rendererSettings: KRRendererSettings
    ) {
        let (width, height) = outputDimensions
        self.renderTargets = RenderStageOpaqueOutput(
            color: Self.createColorTexture(
                device: device,
                pixelFormat: .bgra8Unorm,
                width: width,
                height: height,
                label: "Main stage color output"),
            brightness: rendererSettings.bloomEnabled
                ? Self.createBloomRenderTexture(
                    device: device,
                    width: width,
                    height: height)
                : nil,
            depth: Self.createDepthRenderTexture(
                device: device,
                width: width,
                height: height,
                msaaSampleCount: 1))

        if let outputTargets = renderTargets {
            opaqueTechnique.resize(
                device: device,
                outputDimensions: outputDimensions,
                rendererSettings: rendererSettings,
                outputTargets: outputTargets)
        }
    }

    static func createColorTexture(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        width: Int,
        height: Int,
        label: String
    ) -> MTLTexture {
        let outputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false)
        outputTextureDescriptor.usage = [.shaderWrite, .shaderRead, .renderTarget]
        outputTextureDescriptor.storageMode = .private
        let renderTexture = device.makeTexture(descriptor: outputTextureDescriptor)!
        renderTexture.label = label
        return renderTexture
    }

    static func createBloomRenderTexture(
        device: MTLDevice,
        width: Int,
        height: Int
    ) -> MTLTexture {
        let bloomTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false)
        bloomTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        bloomTextureDescriptor.storageMode = .private
        let bloomTexture = device.makeTexture(descriptor: bloomTextureDescriptor)!
        bloomTexture.label = "Bloom Render Texture"
        return bloomTexture
    }

    static func createDepthRenderTexture(
        device: MTLDevice,
        width: Int,
        height: Int,
        msaaSampleCount: Int
    ) -> MTLTexture {
        let depthTextureDescriptor = MTLTextureDescriptor()
        depthTextureDescriptor.pixelFormat = .depth32Float
        if msaaSampleCount > 1 {
            depthTextureDescriptor.textureType = .type2DMultisample
            depthTextureDescriptor.sampleCount = msaaSampleCount
        } else {
            depthTextureDescriptor.textureType = .type2D
        }
        depthTextureDescriptor.width = width
        depthTextureDescriptor.height = height
        depthTextureDescriptor.mipmapLevelCount = 1
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDescriptor.storageMode = .private
        let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
        depthTexture.label = "Depth Render Texture"
        return depthTexture
    }
}

