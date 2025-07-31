public enum LightUniformsType: Int8 {
    case directional
    case point
}

struct LightUniforms {
    public let float3Data: SIMD3<Float>
    public let intensity: Float
    public let color: SIMD3<Float>
    public let range: Float
    public let attenuation: SIMD3<Float>
    public let type: LightUniformsType

    public init(
        type: LightUniformsType,
        float3Data: SIMD3<Float>,
        color: SIMD3<Float>,
        intensity: Float,
        attenuation: SIMD3<Float>,
        range: Float
    ) {
        self.type = type
        self.float3Data = float3Data
        self.color = color
        self.intensity = intensity
        self.attenuation = attenuation
        self.range = range
    }
}
