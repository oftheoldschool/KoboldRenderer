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

public struct KRMaterial {
    public let name: String
    public let type: KRMaterialType
    let ambientFactor: Float
    let shininess: Float
    let specularIntensity: Float
    let applyLight: Bool
    let receiveShadow: Bool
    let flatShading: Bool

    public init(
        name: String,
        type: KRMaterialType,
        ambientFactor: Float,
        shininess: Float,
        specularIntensity: Float,
        applyLight: Bool,
        receiveShadow: Bool,
        flatShading: Bool
    ) {
        self.name = name
        self.type = type
        self.ambientFactor = ambientFactor
        self.shininess = shininess
        self.specularIntensity = specularIntensity
        self.applyLight = applyLight
        self.flatShading = flatShading
        self.receiveShadow = receiveShadow
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

        return MaterialUniforms(
            color: color,
            ambientFactor: ambientFactor,
            shininess: shininess,
            specularIntensity: specularIntensity,
            materialType: materialType,
            flatShadingMode: flatShading ? .enabled : .global,
            applyLight: applyLight,
            receiveShadow: receiveShadow)
    }
}
