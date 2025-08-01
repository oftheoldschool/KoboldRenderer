public enum KRMaterialType: Hashable {
    case none
    case debugPosition
    case debugNormal
    case debugColor(SIMD3<Float>)
    case debugCascade
    case procedural(SIMD4<Float>)
    case color(SIMD4<Float>)
    case texture
}

public struct KRLightingProperties {
    public let ambientFactor: Float
    public let shininess: Float
    public let specularIntensity: Float

    public init(ambientFactor: Float, shininess: Float, specularIntensity: Float) {
        self.ambientFactor = ambientFactor
        self.shininess = shininess
        self.specularIntensity = specularIntensity
    }
}

public struct KRRimLightingProperties {
    public let intensity: Float
    public let color: SIMD3<Float>
    public let power: Float
    public let mode: KRRimLightingMode

    public init(intensity: Float, color: SIMD3<Float>, power: Float, mode: KRRimLightingMode) {
        self.intensity = intensity
        self.color = color
        self.power = power
        self.mode = mode
    }
}

public struct KRLightingBehavior {
    public let applyLight: Bool
    public let receiveShadow: Bool
    public let flatShading: Bool

    public init(applyLight: Bool, receiveShadow: Bool, flatShading: Bool) {
        self.applyLight = applyLight
        self.receiveShadow = receiveShadow
        self.flatShading = flatShading
    }
}

public enum KRRimLightingMode {
    case none
    case artistic
    case lightInfluenced
    case directional
}

public struct KRMaterial {
    public let name: String
    public let type: KRMaterialType
    public let lighting: KRLightingProperties
    public let rim: KRRimLightingProperties
    public let behavior: KRLightingBehavior

    public init(
        name: String,
        type: KRMaterialType,
        lighting: KRLightingProperties,
        rim: KRRimLightingProperties,
        behavior: KRLightingBehavior
    ) {
        self.name = name
        self.type = type
        self.lighting = lighting
        self.rim = rim
        self.behavior = behavior
    }

    public func hasTransparency() -> Bool {
        return if case let .color(color) = type {
            color.w < 1
        } else {
            false
        }
    }

    func toGPUData() -> MaterialUniforms {
        let (materialType, color): (MaterialUniformsType, SIMD4<Float>) = switch type {
        case .none: (.none, .zero)
        case .debugPosition: (.debugPosition, .zero)
        case .debugNormal: (.debugNormal, .zero)
        case .debugColor(let color): (.debugColor, SIMD4<Float>(color.x, color.y, color.z, 1))
        case .debugCascade: (.debugCascade, .zero)
        case .procedural(let color): (.procedural, color)
        case .color(let color): (.color, color)
        case .texture: (.texture, .zero)
        }

        let rimLightingMode: RimLightingMode = switch rim.mode {
        case .none: .none
        case .artistic: .artistic
        case .lightInfluenced: .lightInfluenced
        case .directional: .directional
        }

        return MaterialUniforms(
            color: color,
            ambientFactor: lighting.ambientFactor,
            shininess: lighting.shininess,
            specularIntensity: lighting.specularIntensity,
            rimIntensity: rim.intensity,
            rimColor: rim.color,
            rimPower: rim.power,
            materialType: materialType,
            flatShadingMode: behavior.flatShading ? .enabled : .global,
            rimLightingMode: rimLightingMode,
            applyLight: behavior.applyLight,
            receiveShadow: behavior.receiveShadow
        )
    }
}
