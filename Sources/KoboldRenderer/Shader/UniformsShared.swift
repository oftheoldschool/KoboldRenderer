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
    let elapsedTime: Float
    let globalMaterialId: Int32
    let enableFlatShading: Bool
}

// general purpose init - used for primary rendering scenarios
// for example perspective camera and lighting
// want to avoid specifying defaults in SharedUniforms though
extension SharedUniforms {
    init(
        camera: KRCamera,
        rendererSettings: KRRendererSettings,
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
            bloomThreshold: rendererSettings.bloomThreshold,
            bloomMultiplier: rendererSettings.bloomMultiplier,
            elapsedTime: elapsedTime,
            globalMaterialId: Int32(globalMaterialId),
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
            elapsedTime: elapsedTime,
            globalMaterialId: 0,
            enableFlatShading: false
        )
    }

    // useful when dealing with colour only scenarios such as when writing the skybox
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
            elapsedTime: elapsedTime,
            globalMaterialId: 0,
            enableFlatShading: false
        )
    }
}
