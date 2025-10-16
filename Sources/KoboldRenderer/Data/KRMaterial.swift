public struct KRProceduralProperties: Hashable {
    public let scale: Float
    public let octaves: Int
    public let persistence: Float
    public let lacunarity: Float
    public let offset: SIMD3<Float>
    public let colorA: SIMD4<Float>
    public let colorB: SIMD4<Float>
    public let threshold: Float
    public let varyWithTime: Bool

    public init(
        scale: Float = 1.0,
        octaves: Int = 4,
        persistence: Float = 0.5,
        lacunarity: Float = 2.0,
        offset: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0),
        colorA: SIMD4<Float> = SIMD4<Float>(0.0, 0.0, 0.0, 1.0),
        colorB: SIMD4<Float> = SIMD4<Float>(1.0, 1.0, 1.0, 1.0),
        threshold: Float = 0.0,
        varyWithTime: Bool = false
    ) {
        self.scale = scale
        self.octaves = octaves
        self.persistence = persistence
        self.lacunarity = lacunarity
        self.offset = offset
        self.colorA = colorA
        self.colorB = colorB
        self.threshold = threshold
        self.varyWithTime = varyWithTime
    }
}

public enum KRMaterialType: Hashable {
    case none
    case debugPosition
    case debugNormal
    case debugColor(SIMD3<Float>)
    case debugCascade
    case procedural(KRProceduralProperties)
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
        let rimLightingMode: RimLightingMode = switch rim.mode {
        case .none: .none
        case .artistic: .artistic
        case .lightInfluenced: .lightInfluenced
        case .directional: .directional
        }

        switch type {
        case .none:
            return MaterialUniforms(
                color: .zero,
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                materialType: .none,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                rimLightingMode: rimLightingMode,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow
            )
        case .debugPosition:
            return MaterialUniforms(
                color: .zero,
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                materialType: .debugPosition,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                rimLightingMode: rimLightingMode,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow
            )
        case .debugNormal:
            return MaterialUniforms(
                color: .zero,
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                materialType: .debugNormal,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                rimLightingMode: rimLightingMode,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow
            )
        case .debugColor(let color):
            return MaterialUniforms(
                color: SIMD4<Float>(color.x, color.y, color.z, 1),
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                materialType: .debugColor,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                rimLightingMode: rimLightingMode,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow
            )
        case .debugCascade:
            return MaterialUniforms(
                color: .zero,
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                materialType: .debugCascade,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                rimLightingMode: rimLightingMode,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow
            )
        case .procedural(let proceduralProps):
            return MaterialUniforms(
                materialType: .procedural,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow,
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                rimLightingMode: rimLightingMode,
                color: proceduralProps.colorA, // Use colorA as the base color for compatibility
                noiseScale: proceduralProps.scale,
                noiseOctaves: Int32(proceduralProps.octaves),
                noisePersistence: proceduralProps.persistence,
                noiseLacunarity: proceduralProps.lacunarity,
                noiseOffset: proceduralProps.offset,
                noiseColorA: proceduralProps.colorA,
                noiseColorB: proceduralProps.colorB,
                noiseThreshold: proceduralProps.threshold,
                varyWithTime: proceduralProps.varyWithTime
            )
        case .color(let color):
            return MaterialUniforms(
                color: color,
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                materialType: .color,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                rimLightingMode: rimLightingMode,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow
            )
        case .texture:
            return MaterialUniforms(
                color: .zero,
                ambientFactor: lighting.ambientFactor,
                shininess: lighting.shininess,
                specularIntensity: lighting.specularIntensity,
                rimIntensity: rim.intensity,
                rimColor: rim.color,
                rimPower: rim.power,
                materialType: .texture,
                flatShadingMode: behavior.flatShading ? .enabled : .global,
                rimLightingMode: rimLightingMode,
                applyLight: behavior.applyLight,
                receiveShadow: behavior.receiveShadow
            )
        }
    }
}
