public enum KROpenSimplex2Noise2Variant: Int8, Hashable {
    case standard
    case x
}

public enum KROpenSimplex2Noise3Variant: Int8, Hashable {
    case xy
    case xz
    case fallback
}

public enum KROpenSimplex2Noise4Variant: Int8, Hashable {
    case xyz
    case xyz_xy
    case xyz_xz
    case xy_zw
    case fallback
}

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

    public let startingAmplitude: Float
    public let startingFrequency: Float
    public let coordinateScale: Float
    public let warpIterations: Int
    public let warpScale: Float

    public let openSimplex2Seed: Int32
    public let openSimplex2Noise2Variant: KROpenSimplex2Noise2Variant
    public let openSimplex2Noise3Variant: KROpenSimplex2Noise3Variant
    public let openSimplex2Noise4Variant: KROpenSimplex2Noise4Variant

    public init(
        scale: Float = 1.0,
        octaves: Int = 4,
        persistence: Float = 0.5,
        lacunarity: Float = 2.0,
        offset: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0),
        colorA: SIMD4<Float> = SIMD4<Float>(0.0, 0.0, 0.0, 1.0),
        colorB: SIMD4<Float> = SIMD4<Float>(1.0, 1.0, 1.0, 1.0),
        threshold: Float = 0.0,
        varyWithTime: Bool = false,
        startingAmplitude: Float = 1.0,
        startingFrequency: Float = 1.0,
        coordinateScale: Float = 1.0,
        warpIterations: Int = 0,
        warpScale: Float = 1.0,
        openSimplex2Seed: Int32 = 1337,
        openSimplex2Noise2Variant: KROpenSimplex2Noise2Variant = .standard,
        openSimplex2Noise3Variant: KROpenSimplex2Noise3Variant = .xy,
        openSimplex2Noise4Variant: KROpenSimplex2Noise4Variant = .xyz
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

        self.startingAmplitude = startingAmplitude
        self.startingFrequency = startingFrequency
        self.coordinateScale = coordinateScale
        self.warpIterations = warpIterations
        self.warpScale = warpScale

        self.openSimplex2Seed = openSimplex2Seed
        self.openSimplex2Noise2Variant = openSimplex2Noise2Variant
        self.openSimplex2Noise3Variant = openSimplex2Noise3Variant
        self.openSimplex2Noise4Variant = openSimplex2Noise4Variant
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

    func toMaterialUniforms() -> MaterialUniforms {
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
        case .procedural(let p):
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
                color: p.colorA,
                noiseOffset: p.offset,
                noiseColorA: p.colorA,
                noiseColorB: p.colorB,
                noiseThreshold: p.threshold,
                varyWithTime: p.varyWithTime,
                fractalLacunarity: p.lacunarity,
                fractalGain: p.persistence,
                fractalStartingAmplitude: p.startingAmplitude,
                fractalStartingFrequency: p.startingFrequency,
                fractalOctaves: Int32(p.octaves),
                fractalWarpIterations: Int32(p.warpIterations),
                fractalWarpScale: p.warpScale,
                fractalCoordinateScale: p.coordinateScale,
                fractalNoiseType: 0,
                openSimplex2Seed: p.openSimplex2Seed,
                openSimplex2Noise2Variant: Int8(p.openSimplex2Noise2Variant.rawValue),
                openSimplex2Noise3Variant: Int8(p.openSimplex2Noise3Variant.rawValue),
                openSimplex2Noise4Variant: Int8(p.openSimplex2Noise4Variant.rawValue),

                voronoiSeed: 0,
                voronoiDistanceFunction: 0,
                voronoiReturnType: 0,
                voronoiJitter: 1.0,
                voronoiMinkowskiP: 2.0
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
