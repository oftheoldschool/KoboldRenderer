public enum LightUniformsType: Int8 {
    case directional
    case point
}

struct LightUniforms {
    public let float3Data: SIMD3<Float>
    public let intensity: Float
    public let color: SIMD3<Float>
    public let ambientStrength: Float
    public let attenuation: SIMD3<Float>
    public let range: Float
    public let specularStrength: Float
    public let specularPower: Float
    public let type: LightUniformsType

    public init(
        type: LightUniformsType,
        float3Data: SIMD3<Float>,
        color: SIMD3<Float>,
        intensity: Float,
        ambientStrength: Float,
        specularStrength: Float,
        specularPower: Float,
        attenuation: SIMD3<Float>,
        range: Float
    ) {
        self.type = type
        self.float3Data = float3Data
        self.color = color
        self.intensity = intensity
        self.ambientStrength = ambientStrength
        self.specularStrength = specularStrength
        self.specularPower = specularPower
        self.attenuation = attenuation
        self.range = range
    }
}
