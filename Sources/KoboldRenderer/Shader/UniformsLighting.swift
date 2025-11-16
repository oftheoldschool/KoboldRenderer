struct LightingUniforms {
    let globalLightingColor: SIMD3<Float>
    let shadowNormalBias: Float
    let shadowBiasAngleFactor: Float
    let shadowCascadeFactor: Float
    let lightCount: UInt8
    let occluderCount: UInt8
    let enableShadows: Bool
    let enableLighting: Bool
}
