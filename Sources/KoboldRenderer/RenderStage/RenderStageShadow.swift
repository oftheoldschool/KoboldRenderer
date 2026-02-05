import MetalKit

struct CascadedShadowMap {
    let lightVolumeViewProjections: [float4x4]
    let cascadeFrustumLimitsClipSpace: [Float]
    let shadowTextureArray: MTLTexture
    let shadowTextureSampler: MTLSamplerState
}

enum RenderError: Error {
    case unsupportedCameraType(String)
    case unsupportedLightType(String)
}

class RenderStageShadow {
    static let defaultCascadeFrustumDistances: [Float] = [50, 500, 0]
    static let defaultBaseTextureSize: Int = 2048

    let shadowTextureArray: MTLTexture
    let shadowTextureSampler: MTLSamplerState
    let cascadedShadowRenderPassDescriptor: MTLRenderPassDescriptor
    let cascadeFrustumDistances: [Float]
    let cascadeCount: Int
    let baseTextureSize: Int

    init(
        device: MTLDevice,
        baseTextureSize: Int = RenderStageShadow.defaultBaseTextureSize,
        cascadeFrustumDistances: [Float] = RenderStageShadow.defaultCascadeFrustumDistances
    ) {
        let cascadeCount = cascadeFrustumDistances.count
        self.cascadeCount = cascadeCount
        self.shadowTextureArray = Self.createCascadedShadowTextureArray(
            device: device,
            baseTextureSize: baseTextureSize,
            cascadeCount: cascadeCount)
        let cascadedShadowSamplerDescriptor = MTLSamplerDescriptor()
        cascadedShadowSamplerDescriptor.label = "Cascaded shadow sampler"
        cascadedShadowSamplerDescriptor.compareFunction = .greaterEqual
        cascadedShadowSamplerDescriptor.normalizedCoordinates = true
        cascadedShadowSamplerDescriptor.rAddressMode = .clampToEdge
        cascadedShadowSamplerDescriptor.sAddressMode = .clampToEdge
        cascadedShadowSamplerDescriptor.tAddressMode = .clampToEdge
        cascadedShadowSamplerDescriptor.minFilter = .linear
        cascadedShadowSamplerDescriptor.magFilter = .linear

        self.shadowTextureSampler = device.makeSamplerState(descriptor: cascadedShadowSamplerDescriptor)!

        self.cascadedShadowRenderPassDescriptor = MTLRenderPassDescriptor()
        self.cascadedShadowRenderPassDescriptor.depthAttachment.loadAction = .clear
        self.cascadedShadowRenderPassDescriptor.depthAttachment.storeAction = .store
        self.cascadedShadowRenderPassDescriptor.depthAttachment.clearDepth = 0
        self.cascadedShadowRenderPassDescriptor.depthAttachment.texture = shadowTextureArray
        self.cascadeFrustumDistances = cascadeFrustumDistances
        self.baseTextureSize = baseTextureSize
    }

    func getCascadeFrustumLimitsCameraSpace(camera: KRCamera) throws -> [Float] {
        guard case let .perspective(cameraVolume) = camera.volume else {
            throw RenderError.unsupportedCameraType("Unable to get frustum limits in camera space")
        }
        return try cameraVolume.calculateFrustumLimitsInCameraSpace(
            frustumRatios: getCascadeFrustumRatios(
                camera: camera))
    }

    func getCascadeFrustumRatios(camera: KRCamera) throws -> [Float] {
        guard case let .perspective(cameraVolume) = camera.volume else {
            throw RenderError.unsupportedCameraType("Unable to get frustum rations")
        }
        let cameraViewDistance = cameraVolume.far

        let viewDistanceUsed: Float = cascadeFrustumDistances.reduce(0){$0 + $1}
        let frustumValues = cascadeFrustumDistances.map {
            $0.isZero ? cameraViewDistance - viewDistanceUsed : $0
        }
        let frustumRatios = frustumValues.map { $0 / cameraViewDistance }
        return frustumRatios
    }

    func renderCascadedShadowMap(
        shaderLibrary: ShaderLibrary, // todo: don't do this - look up pipelines before,
        rendererSettings: KRRendererSettings,
        modelManager: ModelManager,
        renderPass: RenderPass,
        commandBuffer: MTLCommandBuffer,
        drawDataList: [DrawData],
        globalLight: KRLight,
        camera: KRCamera,
        currentFrame: Int
    ) throws -> CascadedShadowMap
    {
        guard case let .perspective(cameraVolume) = camera.volume else {
            throw RenderError.unsupportedCameraType("Unable to render cascaded shadow map")
        }

        let lightDirection = switch globalLight.type {
        case .directional(let directionalLight): directionalLight.direction
        case .point(let pointLight): normalize(camera.position - pointLight.position)
        }

        let orthographicVolumes = cameraVolume.calculateOrthographicVolumesInLightSpace(
            frustumRatios: try getCascadeFrustumRatios(camera: camera),
            currentViewMatrix: camera.viewMatrix(),
            targetViewMatrix: float4x4.lookAt(
                from: .zero,
                to: lightDirection,
                up: SIMD3<Float>.yPositive))

        for i in 0..<cascadeCount {
            cascadedShadowRenderPassDescriptor.depthAttachment.slice = i

            let cascadeVolume = orthographicVolumes[i]

            let lightVolume = KRVolumeOrthographic(
                left: cascadeVolume.left,
                right: cascadeVolume.right,
                top: cascadeVolume.top,
                bottom: cascadeVolume.bottom,
                near: -cascadeVolume.near,
                far: -cascadeVolume.far)

            let projectionMatrix = lightVolume.toMatrix()
            let viewMatrix = float4x4.lookAt(
                from: .zero,
                to: lightDirection,
                up: .yPositive)

            let sharedUniforms = SharedUniforms(
                projectionMatrix: projectionMatrix,
                viewMatrix: viewMatrix)

            let dataBindings: [KBufferBindingType: GPUData] = [
                .uniformsShared: .wrapper(
                    GPUDataWrapper(sharedUniforms)),
            ]

            renderPass.render(
                shaderLibrary: shaderLibrary,
                modelManager: modelManager,
                commandBuffer: commandBuffer,
                outputRenderPassDescriptor: cascadedShadowRenderPassDescriptor,
                drawDataList: drawDataList
                    .filter { $0.castsShadow }
                    .filter { !$0.isOccluder },
                dataBindings: dataBindings,
                currentFrame: currentFrame,
                renderTarget: .depth,
                isShadowPass: true,
                rendererSettings: rendererSettings)
        }

        let lightVolumeViewProjections = orthographicVolumes.map { lightVolume in
            let lightView = float4x4.lookAt(
                from: .zero,
                to: lightDirection,
                up: .yPositive)
            let lightProjection = float4x4.orthographicProjection(
                left: lightVolume.left, right: lightVolume.right,
                bottom: lightVolume.bottom, top: lightVolume.top,
                near: -lightVolume.near, far: -lightVolume.far)
            return lightProjection * lightView
        }

        let cascadeFrustumLimitsCameraSpace = try getCascadeFrustumLimitsCameraSpace(camera: camera)
        let cascadeFrustumLimitsClipSpace = cascadeFrustumLimitsCameraSpace[1...]
            .map { camera.projectionMatrix() * SIMD4<Float>(0, 0, -$0, 1) }
            .map { $0.z }

        return CascadedShadowMap(
            lightVolumeViewProjections: lightVolumeViewProjections,
            cascadeFrustumLimitsClipSpace: cascadeFrustumLimitsClipSpace,
            shadowTextureArray: shadowTextureArray,
            shadowTextureSampler: shadowTextureSampler
        )
    }

    static func createCascadedShadowTextureArray(
        device: MTLDevice,
        baseTextureSize: Int,
        cascadeCount: Int
    ) -> MTLTexture {
        let shadowTextureDescriptor = MTLTextureDescriptor()
        shadowTextureDescriptor.pixelFormat = .depth32Float
        shadowTextureDescriptor.textureType = .type2DArray
        shadowTextureDescriptor.width = baseTextureSize
        shadowTextureDescriptor.height = baseTextureSize
        shadowTextureDescriptor.arrayLength = cascadeCount
        shadowTextureDescriptor.mipmapLevelCount = 1
        shadowTextureDescriptor.usage = [.renderTarget, .shaderRead]
        shadowTextureDescriptor.storageMode = .private
        let shadowTexture = device.makeTexture(descriptor: shadowTextureDescriptor)!
        shadowTexture.label = "Cascaded Shadow Texture Array"
        return shadowTexture
    }
}
