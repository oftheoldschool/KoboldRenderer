public struct KRLightTypeDirectional {
    public let direction: SIMD3<Float>

    public init(direction: SIMD3<Float>) {
        self.direction = direction
    }
}

public struct KRLightTypePoint {
    public let position: SIMD3<Float>
    public let attenuation: SIMD3<Float>
    public let range: Float

    public init(
        position: SIMD3<Float>,
        attenuationConstant: Float,
        attenuationLinear: Float,
        attenuationQuadratic: Float,
        range: Float
    ) {
        self.position = position
        self.attenuation = SIMD3<Float>(
            attenuationConstant,
            attenuationLinear,
            attenuationQuadratic
        )
        self.range = range
    }
}

public enum KRLightType {
    case directional(KRLightTypeDirectional)
    case point(KRLightTypePoint)
}

public struct KRLight {
    let type: KRLightType
    let color: SIMD3<Float>
    let intensity: Float
    let ambientStrength: Float
    let specularStrength: Float
    let specularPower: Float

    public init(
        type: KRLightType,
        color: SIMD3<Float>,
        intensity: Float,
        ambientStrength: Float,
        specularStrength: Float,
        specularPower: Float
    ) {
        self.specularPower = specularPower
        self.type = type
        self.intensity = intensity
        self.color = color
        self.ambientStrength = ambientStrength
        self.specularStrength = specularStrength
    }
}
