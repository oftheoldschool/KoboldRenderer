import Metal
import MetalKit
import MetalPerformanceShaders

public class KRRenderer {
    public static let maxFramesInFlight: Int = 3
    public static let maxLights: Int = 64
    public static let maxOccluders: Int = 8
    public static let maxMaterials: Int = 64

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let gpuDataManager: GPUDataManager
    private let modelManager: ModelManager

    private let renderPass: RenderPass
    private var renderStageShadow: RenderStageShadow
    private let renderStageOpaque: RenderStageOpaque
    private var renderStageTransparent: RenderStageTransparent
    private let renderStageWriteOutput: RenderStageWriteOutput

    private let materialsBuffer: GPUDataMultiBuffer
    private let lightsBuffer: GPUDataMultiBuffer
    private let occludersBuffer: GPUDataMultiBuffer
    private var instanceBuffers: [String: GPUDataMultiBuffer]

    private let layoutLibrary: LayoutLibrary
    public var shaderLibrary: ShaderLibrary
    private var additionalPipelineDefinitions: [RenderPipelineDefinition]
    private var additionalShaderCode: [String]
    private var additionalVertexFunctionTemplates: [VertexShaderFunctionTemplate.Type]
    private var additionalFragmentFunctionTemplates: [FragmentShaderFunctionTemplate.Type]
    private var additionalComputeFunctionTemplates: [ComputeShaderFunctionTemplate.Type]

    public var currentFrame: Int
    private let inflightSemaphore: DispatchSemaphore

    private var bounds: (width: Int, height: Int)
    private var needsInit: Bool
    private var needsResize: Bool
    private var rendererSettingsToApply: KRRendererSettings?

    public var rendererSettings: KRRendererSettings

    // temporary during refactor - this should belong to a compositing stage
    var blurFunction: MPSImageGaussianBlur
    let addFunction: MPSImageAdd
    var postProcessedTexture: TextureData?
    var combinePipeline: ComputePipelineCombine

    public init(
        device: MTLDevice,
        rendererSettings: KRRendererSettings,
        gpuDataManager: GPUDataManager,
        additionalPipelineDefinitions: [RenderPipelineDefinition] = [],
        additionalLayouts: KRendererLayouts? = nil,
        additionalShaderCode: [String] = [],
        additionalVertexFunctionTemplates: [VertexShaderFunctionTemplate.Type] = [],
        additionalFragmentFunctionTemplates: [FragmentShaderFunctionTemplate.Type] = [],
        additionalComputeFunctionTemplates: [ComputeShaderFunctionTemplate.Type] = []
    ) throws {
        self.blurFunction = MPSImageGaussianBlur(
            device: device,
            sigma: rendererSettings.bloomGaussianBlurSigma)
        self.addFunction = MPSImageAdd(device: device)
        self.postProcessedTexture = nil

        self.device = device
        self.gpuDataManager = gpuDataManager
        self.commandQueue = device.makeCommandQueue()!
        self.additionalShaderCode = additionalShaderCode
        self.additionalPipelineDefinitions = additionalPipelineDefinitions
        self.additionalVertexFunctionTemplates = additionalVertexFunctionTemplates
        self.additionalFragmentFunctionTemplates = additionalFragmentFunctionTemplates
        self.additionalComputeFunctionTemplates = additionalComputeFunctionTemplates

        self.modelManager = ModelManager(
            device: device,
            gpuDataManager: gpuDataManager)

        self.needsResize = false
        self.needsInit = false
        self.rendererSettings = rendererSettings
        self.rendererSettingsToApply = nil
        self.bounds = (width: .zero, height: .zero)
        self.inflightSemaphore = DispatchSemaphore(value: Self.maxFramesInFlight)
        self.currentFrame = 0

        self.renderPass = RenderPass(device: device)
        self.renderStageWriteOutput = RenderStageWriteOutput()
        self.renderStageShadow = RenderStageShadow(
            device: device,
            cascadeFrustumDistances: rendererSettings.cascadeFrustumDistances)

        self.layoutLibrary = LayoutLibrary(additionalLayouts: additionalLayouts)
        self.shaderLibrary = try ShaderLibrary(
            device: device,
            layoutLibrary: self.layoutLibrary,
            renderingMode: rendererSettings.renderingMode,
            shadowTextureNumCascades: renderStageShadow.cascadeCount,
            shadowBaseTextureSize: renderStageShadow.baseTextureSize,
            msaaSampleCount: rendererSettings.msaaEnabled ? rendererSettings.msaaSampleCount : 1,
            additionalRenderPipelineDefinitions: additionalPipelineDefinitions,
            additionalShaderCode: additionalShaderCode,
            additionalVertexFunctionTemplates: additionalVertexFunctionTemplates,
            additionalFragmentFunctionTemplates: additionalFragmentFunctionTemplates,
            additionalComputeFunctionTemplates: additionalComputeFunctionTemplates)

        // todo: make this a separate render stage
        self.combinePipeline = shaderLibrary.getComputePipeline("computeShaderCombine")

        self.renderStageOpaque = RenderStageOpaque(
            device: device,
            rendererSettings: rendererSettings,
            shaderLibrary: shaderLibrary)

        self.renderStageTransparent = RenderStageTransparent(
            device: device,
            shaderLibrary: shaderLibrary,
            rendererSettings: rendererSettings)

        self.materialsBuffer = GPUDataMultiBuffer(
            gpuDataManager: gpuDataManager,
            count: Self.maxFramesInFlight,
            length: MemoryLayout<MaterialUniforms>.stride * Self.maxMaterials)

        self.lightsBuffer = GPUDataMultiBuffer(
            gpuDataManager: gpuDataManager,
            count: Self.maxFramesInFlight,
            length: MemoryLayout<LightUniforms>.stride * Self.maxLights)

        self.occludersBuffer = GPUDataMultiBuffer(
            gpuDataManager: gpuDataManager,
            count: Self.maxFramesInFlight,
            length: MemoryLayout<OccluderUniforms>.stride * Self.maxOccluders)

        self.instanceBuffers = [:]
    }

    public func handleRenderSettingsChange(_ rendererSettingsToApply: KRRendererSettings) {
        if rendererSettingsToApply.requiresReinit(previous: rendererSettings) {
            self.rendererSettingsToApply = rendererSettingsToApply
            self.needsInit = true
            self.needsResize = true
        } else if rendererSettingsToApply.requiresResize(previous: rendererSettings) {
            self.rendererSettings = rendererSettingsToApply
            self.needsResize = true
        } else {
            self.rendererSettings = rendererSettingsToApply
            self.blurFunction = MPSImageGaussianBlur(
                device: device,
                sigma: rendererSettings.bloomGaussianBlurSigma)
        }
    }

    public func loadModels(_ modelInputs: [KRModelInput]) {
        modelInputs.forEach { modelInput in
            modelManager.loadModel(modelInput: modelInput)
        }
    }

    public func handleResize(width: Int, height: Int) {
        self.needsResize = true
        self.bounds = (width: width, height: height)
    }

    public func writeSkybox(
        drawDataList: [KRDrawData],
        materials: [KRMaterial],
        bloomThreshold: SIMD3<Float>,
        bloomMultiplier: SIMD3<Float>,
        elapsedTime: Float
    ) -> KRModelInput? {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }
        materialsBuffer[currentFrame].copy(data: materials.map { $0.toMaterialUniforms() })
        let updatedDrawDataList = drawDataList.map(getInternalDrawData)

        let renderStageWriteSkybox = RenderStageWriteSkyBox()
        let skyboxModel = renderStageWriteSkybox.writeSkybox(
            device: device,
            shaderLibrary: shaderLibrary,
            gpuDataManager: gpuDataManager,
            modelManager: modelManager,
            skyboxSize: 1024,
            renderPass: renderPass,
            commandBuffer: commandBuffer,
            drawDataList: updatedDrawDataList,
            materialBuffer: materialsBuffer[currentFrame],
            bloomThreshold: bloomThreshold,
            bloomMultiplier: bloomMultiplier,
            elapsedTime: elapsedTime,
            rendererSettings: rendererSettings)

        commandBuffer.commit()

        return skyboxModel
    }

    @MainActor
    public func draw(
        mtkView: MTKView?,
        camera: KRCamera,
        globalLight: KRLight,
        globalMaterialId: Int,
        lights: [KRLight],
        occluders: [KROccluder],
        materials: [KRMaterial],
        drawDataList: [KRDrawData],
        additionalBufferBindings: [KBufferBindingType: GPUData] = [:],
        additionalTextureBindings: [KTextureBindingType: GPUTexture] = [:],
        elapsedTime: Float
    ) {
        if needsResize || needsInit {
            applyChanges()
        }

        guard
            let view = mtkView,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let drawable = view.currentDrawable,
            let outputRenderPassDescriptor = view.currentRenderPassDescriptor,
            bounds.width != 0 && bounds.height != 0
        else {
            return
        }

        if inflightSemaphore.wait(timeout: DispatchTime.distantFuture) == .timedOut {
            fatalError("Unable to acquire semaphore for frame")
        }

        let opaqueDrawData = drawDataList
            .filter { !$0.hasTransparency || !rendererSettings.transparencyEnabled }
            .map(getInternalDrawData)

        let boundingBoxDrawData = drawDataList
            .filter { $0.drawBoundingBox }
            .compactMap { createBoundingBoxDrawData(for: $0, materials: materials) }

        let fullOpaqueDrawData = opaqueDrawData + boundingBoxDrawData

        let cascadedShadowMap = try! renderStageShadow.renderCascadedShadowMap(
            shaderLibrary: shaderLibrary,
            rendererSettings: rendererSettings,
            modelManager: modelManager,
            renderPass: renderPass,
            commandBuffer: commandBuffer,
            drawDataList: fullOpaqueDrawData,
            globalLight: globalLight,
            camera: camera,
            currentFrame: currentFrame)

        let lightingData = LightingData(
            globalLight: globalLight,
            maxLights: Self.maxLights,
            maxOccluders: Self.maxOccluders,
            lights: lights,
            occluders: occluders,
            cascadedShadowMap: cascadedShadowMap,
            enableLighting: rendererSettings.lightingEnabled,
            enableShadows: rendererSettings.shadowsEnabled)

        // todo: make Lighting a stateful concept and have it store lights buffer? responsible for max light setting?
        lightsBuffer[currentFrame].copy(data: lightingData.toLightUniforms())
        occludersBuffer[currentFrame].copy(data: occluders.map { $0.toOccluderUniforms() })
        materialsBuffer[currentFrame].copy(data: materials.map { $0.toMaterialUniforms() })

        guard let opaqueTargets = renderStageOpaque.render(
            shaderLibrary: shaderLibrary,
            rendererSettings: rendererSettings,
            renderPass: renderPass,
            commandBuffer: commandBuffer,
            currentFrame: currentFrame,
            elapsedTime: elapsedTime,
            camera: camera,
            lightingData: lightingData,
            modelManager: modelManager,
            materialsBuffer: materialsBuffer,
            globalMaterialId: globalMaterialId,
            globalLightingColor: rendererSettings.globalLightingColor,
            lightsBuffer: lightsBuffer,
            occludersBuffer: occludersBuffer,
            additionalBufferBindings: additionalBufferBindings,
            additionalTextureBindings: additionalTextureBindings,
            drawDataList: fullOpaqueDrawData
        ) else {
            return
        }

        let transparentDrawData = drawDataList
            .filter { $0.hasTransparency }
            .map(getInternalDrawData)

        let transparencyRequired = rendererSettings.transparencyEnabled && !transparentDrawData.isEmpty

        var transparentTargets: RenderStageTransparentOutput?
        if transparencyRequired {
            transparentTargets = renderStageTransparent.render(
                shaderLibrary: shaderLibrary,
                rendererSettings: rendererSettings,
                renderPass: renderPass,
                commandBuffer: commandBuffer,
                currentFrame: currentFrame,
                elapsedTime: elapsedTime,
                camera: camera,
                lightingData: lightingData,
                modelManager: modelManager,
                materialsBuffer: materialsBuffer,
                globalMaterialId: globalMaterialId,
                globalLightingColor: rendererSettings.globalLightingColor,
                lightsBuffer: lightsBuffer,
                occludersBuffer: occludersBuffer,
                additionalBufferBindings: additionalBufferBindings,
                additionalTextureBindings: additionalTextureBindings,
                drawDataList: transparentDrawData,
                opaqueDepthTexture: opaqueTargets.depth)
        }

        if rendererSettings.bloomEnabled, var bloomTexture = opaqueTargets.brightness {
            blurFunction.edgeMode = .clamp
            blurFunction.encode(commandBuffer: commandBuffer, inPlaceTexture: &bloomTexture)

            if var alphaBloomTexture = transparentTargets?.accumulationBrightness {
                blurFunction.encode(commandBuffer: commandBuffer, inPlaceTexture: &alphaBloomTexture)
            }
        }

        if transparencyRequired, let transparentTargets = transparentTargets {
            combinePipeline.combine(
                commandBuffer: commandBuffer,
                opaqueOutput: opaqueTargets,
                transparentOutput: transparentTargets,
                outputTexture: postProcessedTexture!.texture,
                rendererSettings: rendererSettings)
        } else {
            let colorTexture = opaqueTargets.color
            if rendererSettings.bloomEnabled, var bloomTexture = opaqueTargets.brightness {
                blurFunction.edgeMode = .clamp
                blurFunction.encode(commandBuffer: commandBuffer, inPlaceTexture: &bloomTexture)

                addFunction.encode(
                    commandBuffer: commandBuffer,
                    primaryTexture: colorTexture,
                    secondaryTexture: bloomTexture,
                    destinationTexture: postProcessedTexture!.texture)
            } else {
                let blitEncoder = commandBuffer.makeBlitCommandEncoder()!

                blitEncoder.copy(
                    from: colorTexture,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                    sourceSize: MTLSize(
                        width: colorTexture.width,
                        height: colorTexture.height,
                        depth: 1
                    ),
                    to: postProcessedTexture!.texture,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
                )

                blitEncoder.endEncoding()
            }
        }

        renderStageWriteOutput.render(
            commandBuffer: commandBuffer,
            outputRenderPassDescriptor: outputRenderPassDescriptor,
            shaderLibrary: shaderLibrary,
            outputTexture: postProcessedTexture!)

        commandBuffer.present(drawable)

        let blockSemaphore = inflightSemaphore

        let handler: @Sendable (MTLCommandBuffer) -> Void = { _ in
            blockSemaphore.signal()
        }
        commandBuffer.addCompletedHandler(handler)
        commandBuffer.commit()

        currentFrame = (currentFrame + 1) % Self.maxFramesInFlight
    }

    private func getPerObjectBufferBindings(_ drawData: KRDrawData) -> [KBufferBindingType: GPUData] {
        var perObjectBufferBindings: [KBufferBindingType: GPUData] = [:]
        if drawData.instanceCount > 1 {
            if !instanceBuffers.keys.contains(drawData.instanceKey!) {
                // todo: don't allocate while rendering!
                // todo: separate concept of max instances vs. active instances since the buffer shouldn't change size
                // todo: when are unused instance buffers cleaned up?
                let instanceBuffer = GPUDataMultiBuffer(
                    gpuDataManager: gpuDataManager,
                    count: KRRenderer.maxFramesInFlight,
                    length: drawData.instanceCount * MemoryLayout<DrawObjectUniforms>.stride)
                instanceBuffers[drawData.instanceKey!] = instanceBuffer
            }
            let instanceUniformsBuffer = instanceBuffers[drawData.instanceKey!]!.bufferArray[currentFrame]

            let uniforms = drawData.instanceData.map { instance in
                DrawObjectUniforms(
                    model: instance.model,
                    normalMatrix: instance.model.normalMatrix,
                    materialId: Int32(instance.materialId))
            }
            instanceUniformsBuffer.copy(data: uniforms)
            perObjectBufferBindings += [
                .uniformsObject: .buffer(
                    GPUDataBuffer(
                        buffer: instanceUniformsBuffer.buffer,
                        offset: instanceUniformsBuffer.offset,
                        length: instanceUniformsBuffer.length)),
            ]
        } else {
            let instance = drawData.instanceData.first!
            let uniforms = [
                DrawObjectUniforms(
                    model: instance.model,
                    normalMatrix: instance.model.normalMatrix,
                    materialId: Int32(instance.materialId))
            ]
            perObjectBufferBindings += [
                .uniformsObject: .wrapper(
                    GPUDataWrapper(uniforms)),
            ]
        }

        if !drawData.pose.isEmpty && !drawData.inverseBindPose.isEmpty {
            perObjectBufferBindings += [
                .uniformsAnimationPose: .wrapper(GPUDataWrapper(drawData.pose)),
                .uniformsAnimationInverseBindPose: .wrapper(GPUDataWrapper(drawData.inverseBindPose)),
            ]
        }

        return perObjectBufferBindings
    }

    private func getInternalDrawData(_ drawData: KRDrawData) -> DrawData {
        return DrawData(
            model: drawData.model,
            pipeline: drawData.pipeline,
            instanceCount: drawData.instanceCount,
            perObjectBufferBindings: getPerObjectBufferBindings(drawData),
            drawFirst: drawData.drawFirst,
            castsShadow: drawData.castsShadow,
            isOccluder: drawData.isOccluder,
            drawBoundingBox: drawData.drawBoundingBox)
    }

    private func applyChanges() {
        for _ in 0..<Self.maxFramesInFlight {
            if inflightSemaphore.wait(timeout: DispatchTime.distantFuture) == .timedOut {
                fatalError("Unable to acquire semaphore for frame")
            }
        }

        if needsInit, let newRendererSettings = rendererSettingsToApply {
            rendererSettings = newRendererSettings
            let msaaSampleCount = rendererSettings.msaaEnabled ? rendererSettings.msaaSampleCount : 1

            self.shaderLibrary = try! ShaderLibrary(
                device: device,
                layoutLibrary: layoutLibrary,
                renderingMode: rendererSettings.renderingMode,
                shadowTextureNumCascades: renderStageShadow.cascadeCount,
                shadowBaseTextureSize: renderStageShadow.baseTextureSize,
                msaaSampleCount: msaaSampleCount,
                additionalRenderPipelineDefinitions: additionalPipelineDefinitions,
                additionalShaderCode: additionalShaderCode,
                additionalVertexFunctionTemplates: additionalVertexFunctionTemplates,
                additionalFragmentFunctionTemplates: additionalFragmentFunctionTemplates,
                additionalComputeFunctionTemplates: additionalComputeFunctionTemplates)

            renderStageOpaque.applyChanges(
                rendererSettings: rendererSettings,
                shaderLibrary: shaderLibrary)

            self.renderStageShadow = RenderStageShadow(
                device: device,
                cascadeFrustumDistances: rendererSettings.cascadeFrustumDistances)

            self.needsInit = false
            self.rendererSettingsToApply = nil
        }

        if needsResize {
            let (width, height) = (Int(Float(bounds.width) * rendererSettings.outputImageScale), Int(Float(bounds.height) * rendererSettings.outputImageScale))

            renderStageOpaque.resize(
                device: device,
                outputDimensions: (width, height),
                rendererSettings: rendererSettings)

            renderStageTransparent.resize(
                device: device,
                outputDimensions: (width, height),
                rendererSettings: rendererSettings)

            postProcessedTexture = Self.createPostProcessedTexture(
                device: device,
                pixelFormat: .bgra8Unorm,
                width: width,
                height: height)

            needsResize = false
        }

        for _ in 0..<Self.maxFramesInFlight {
            inflightSemaphore.signal()
        }
    }

    static func createPostProcessedTexture(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        width: Int,
        height: Int
    ) -> TextureData {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.compareFunction = .lessEqual
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.rAddressMode = .repeat
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        let postProcessedSampler = device.makeSamplerState(descriptor: samplerDescriptor)!

        let outputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false)
        outputTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        outputTextureDescriptor.storageMode = .private

        let renderTexture = device.makeTexture(descriptor: outputTextureDescriptor)!
        renderTexture.label = "Post Processed Texture"

        return TextureData(
            texture: renderTexture,
            sampler: postProcessedSampler)
    }

    private func createBoundingBoxDrawData(
        for drawData: KRDrawData,
        materials: [KRMaterial]
    ) -> DrawData? {
        guard drawData.instanceCount > 0,
              let sourceModel = modelManager.models[drawData.model],
              let debugMaterialId = materials.firstIndex(where: { $0.name == "debugBoundingBox" })
        else {
            return nil
        }

        let boundingBoxUniforms = drawData.instanceData.map { instanceData in
            let modelMatrix = instanceData.model

            let center = (sourceModel.boundingBox.min + sourceModel.boundingBox.max) / 2
            let dimensions = sourceModel.boundingBox.max - sourceModel.boundingBox.min

            let scaleMatrix = float4x4(scaleBy: dimensions / 2)
            let translationMatrix = float4x4(translationBy: center)
            let boundingBoxModelMatrix = modelMatrix * translationMatrix * scaleMatrix

            return DrawObjectUniforms(
                model: boundingBoxModelMatrix,
                normalMatrix: boundingBoxModelMatrix.normalMatrix,
                materialId: Int32(debugMaterialId))
        }

        let perObjectBufferBindings: [KBufferBindingType: GPUData] = [
            .uniformsObject: .wrapper(GPUDataWrapper(boundingBoxUniforms)),
        ]

        return DrawData(
            model: "debugBoundingBox",
            pipeline: "DebugBoundingBox",
            instanceCount: drawData.instanceCount,
            perObjectBufferBindings: perObjectBufferBindings,
            drawFirst: false,
            castsShadow: false,
            isOccluder: false,
            drawBoundingBox: false
        )
    }
}
