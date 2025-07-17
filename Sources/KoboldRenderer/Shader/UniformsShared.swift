import simd

struct SharedUniforms {
    let viewProjection: float4x4
    let invViewProjection: float4x4
    let invViewMatrix: float4x4
    let invProjectionMatrix: float4x4
    let noTranslationViewProjection: float4x4
    let cameraPosition: SIMD3<Float>
    let bloomThreshold: SIMD3<Float>
    let bloomMultiplier: SIMD3<Float>
    let globalLightingColor: SIMD3<Float>
    let elapsedTime: Float
    let globalMaterialId: Int32
    let lightCount: UInt8
    let enableShadows: Bool
    let enableLighting: Bool
    let enableFlatShading: Bool
}

extension SharedUniforms {
    // general purpose init - used for primary rendering scenarios
    // for example perspective camera and lighting
    init(
        camera: KRCamera,
        lightingData: LightingData,
        rendererSettings: KRRendererSettings,
        globalLightingColor: SIMD3<Float>,
        elapsedTime: Float,
        globalMaterialId: Int
    ) {
        let viewMatrix = camera.viewMatrix()
        let projectionMatrix = camera.projectionMatrix()
        let viewProjection = projectionMatrix * viewMatrix

        self.init(
            viewProjection: viewProjection,
            invViewProjection: viewProjection.inverse,
            invViewMatrix: viewMatrix.inverse,
            invProjectionMatrix: projectionMatrix.inverse,
            noTranslationViewProjection: projectionMatrix * viewMatrix.upperLeft.toFloat4x4(),
            cameraPosition: camera.position,
            bloomThreshold: lightingData.bloomThreshold,
            bloomMultiplier: lightingData.bloomMultiplier,
            globalLightingColor: globalLightingColor,
            elapsedTime: elapsedTime,
            globalMaterialId: Int32(globalMaterialId),
            lightCount: UInt8(lightingData.lights.count),
            enableShadows: lightingData.enableShadows,
            enableLighting: lightingData.enableLighting,
            enableFlatShading: rendererSettings.flatShadingEnabled
        )
    }

    // useful when dealing with orthographic volumes directly rather than camera
    // for example shadow volumes
    init(
        projectionMatrix: float4x4,
        viewMatrix: float4x4,
        elapsedTime: Float = .zero
    ) {
        let viewProjectionMatrix = projectionMatrix * viewMatrix

        self.init(
            viewProjection: viewProjectionMatrix,
            invViewProjection: viewProjectionMatrix.inverse,
            invViewMatrix: viewMatrix.inverse,
            invProjectionMatrix: projectionMatrix.inverse,
            noTranslationViewProjection: projectionMatrix * viewMatrix.upperLeft.toFloat4x4(),
            cameraPosition: .zero,
            bloomThreshold: .zero,
            bloomMultiplier: .zero,
            globalLightingColor: .zero,
            elapsedTime: elapsedTime,
            globalMaterialId: 0,
            lightCount: .zero,
            enableShadows: false,
            enableLighting: false,
            enableFlatShading: false)
    }

    // useful when dealing with no lighting info for example rendering skybox
    init(
        camera: KRCamera,
        elapsedTime: Float = .zero
    ) {
        let viewMatrix = camera.viewMatrix()
        let projectionMatrix = camera.projectionMatrix()
        let viewProjectionMatrix = projectionMatrix * viewMatrix

        self.init(
            viewProjection: viewProjectionMatrix,
            invViewProjection: viewProjectionMatrix.inverse,
            invViewMatrix: viewMatrix.inverse,
            invProjectionMatrix: projectionMatrix.inverse,
            noTranslationViewProjection: projectionMatrix * viewMatrix.upperLeft.toFloat4x4(),
            cameraPosition: camera.position,
            bloomThreshold: .zero,
            bloomMultiplier: .zero,
            globalLightingColor: .zero,
            elapsedTime: elapsedTime,
            globalMaterialId: 0,
            lightCount: .zero,
            enableShadows: false,
            enableLighting: false,
            enableFlatShading: false)
    }
}
