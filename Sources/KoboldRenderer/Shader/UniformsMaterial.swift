enum MaterialUniformsType: Int8 {
    case none
    case debugPosition
    case debugNormal
    case debugColor
    case debugCascade
    case procedural
    case color
    case texture
}

enum FlatShadingMode: Int8 {
    case global
    case disabled
    case enabled
}

enum RimLightingMode: Int8 {
    case none
    case artistic
    case lightInfluenced
    case directional
}

struct MaterialUniforms {
    let materialType: MaterialUniformsType
    let flatShadingMode: FlatShadingMode
    let applyLight: Bool
    let receiveShadow: Bool

    let ambientFactor: Float
    let shininess: Float
    let specularIntensity: Float
    let rimIntensity: Float
    let rimColor: SIMD3<Float>
    let rimPower: Float
    let rimLightingMode: RimLightingMode

    let color: SIMD4<Float>

    let noiseOffset: SIMD3<Float>
    let noiseColorA: SIMD4<Float>
    let noiseColorB: SIMD4<Float>
    let noiseThreshold: Float
    let varyWithTime: Bool
    let fractalLacunarity: Float
    let fractalGain: Float
    let fractalStartingAmplitude: Float
    let fractalStartingFrequency: Float
    let fractalOctaves: Int32
    let fractalWarpIterations: Int32
    let fractalWarpScale: Float
    let fractalCoordinateScale: Float

    let fractalNoiseType: Int8

    let openSimplex2Seed: Int32
    let openSimplex2Noise2Variant: Int8
    let openSimplex2Noise3Variant: Int8
    let openSimplex2Noise4Variant: Int8

    let voronoiSeed: Int32
    let voronoiDistanceFunction: Int8
    let voronoiReturnType: Int8
    let voronoiJitter: Float
    let voronoiMinkowskiP: Float

    init(
        color: SIMD4<Float>,
        ambientFactor: Float,
        shininess: Float,
        specularIntensity: Float,
        rimIntensity: Float,
        rimColor: SIMD3<Float>,
        rimPower: Float,
        materialType: MaterialUniformsType,
        flatShadingMode: FlatShadingMode,
        rimLightingMode: RimLightingMode,
        applyLight: Bool,
        receiveShadow: Bool
    ) {
        self.materialType = materialType
        self.flatShadingMode = flatShadingMode
        self.applyLight = applyLight
        self.receiveShadow = receiveShadow

        self.ambientFactor = ambientFactor
        self.shininess = shininess
        self.specularIntensity = specularIntensity
        self.rimIntensity = rimIntensity
        self.rimColor = rimColor
        self.rimPower = rimPower
        self.rimLightingMode = rimLightingMode

        self.color = color

        self.noiseOffset = SIMD3<Float>(0.0, 0.0, 0.0)
        self.noiseColorA = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        self.noiseColorB = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
        self.noiseThreshold = 0.0
        self.varyWithTime = false

        self.fractalLacunarity = 2.0
        self.fractalGain = 0.5
        self.fractalStartingAmplitude = 1.0
        self.fractalStartingFrequency = 1.0
        self.fractalOctaves = 4
        self.fractalWarpIterations = 1
        self.fractalWarpScale = 1.0
        self.fractalCoordinateScale = 1.0
        self.fractalNoiseType = 0

        self.openSimplex2Seed = 0
        self.openSimplex2Noise2Variant = 0
        self.openSimplex2Noise3Variant = 0
        self.openSimplex2Noise4Variant = 0

        self.voronoiSeed = 0
        self.voronoiDistanceFunction = 0
        self.voronoiReturnType = 0
        self.voronoiJitter = 1.0
        self.voronoiMinkowskiP = 2.0
    }

    init(
        materialType: MaterialUniformsType,
        flatShadingMode: FlatShadingMode,
        applyLight: Bool,
        receiveShadow: Bool,
        ambientFactor: Float,
        shininess: Float,
        specularIntensity: Float,
        rimIntensity: Float,
        rimColor: SIMD3<Float>,
        rimPower: Float,
        rimLightingMode: RimLightingMode,
        color: SIMD4<Float>,
        noiseOffset: SIMD3<Float>,
        noiseColorA: SIMD4<Float>,
        noiseColorB: SIMD4<Float>,
        noiseThreshold: Float,
        varyWithTime: Bool,
        fractalLacunarity: Float,
        fractalGain: Float,
        fractalStartingAmplitude: Float,
        fractalStartingFrequency: Float,
        fractalOctaves: Int32,
        fractalWarpIterations: Int32,
        fractalWarpScale: Float,
        fractalCoordinateScale: Float,
        fractalNoiseType: Int8,
        openSimplex2Seed: Int32,
        openSimplex2Noise2Variant: Int8,
        openSimplex2Noise3Variant: Int8,
        openSimplex2Noise4Variant: Int8,
        voronoiSeed: Int32,
        voronoiDistanceFunction: Int8,
        voronoiReturnType: Int8,
        voronoiJitter: Float,
        voronoiMinkowskiP: Float
    ) {
        self.materialType = materialType
        self.flatShadingMode = flatShadingMode
        self.applyLight = applyLight
        self.receiveShadow = receiveShadow
        self.ambientFactor = ambientFactor
        self.shininess = shininess
        self.specularIntensity = specularIntensity
        self.rimIntensity = rimIntensity
        self.rimColor = rimColor
        self.rimPower = rimPower
        self.rimLightingMode = rimLightingMode
        self.color = color

        self.noiseOffset = noiseOffset
        self.noiseColorA = noiseColorA
        self.noiseColorB = noiseColorB
        self.noiseThreshold = noiseThreshold
        self.varyWithTime = varyWithTime

        self.fractalLacunarity = fractalLacunarity
        self.fractalGain = fractalGain
        self.fractalStartingAmplitude = fractalStartingAmplitude
        self.fractalStartingFrequency = fractalStartingFrequency
        self.fractalOctaves = fractalOctaves
        self.fractalWarpIterations = fractalWarpIterations
        self.fractalWarpScale = fractalWarpScale
        self.fractalCoordinateScale = fractalCoordinateScale

        self.fractalNoiseType = fractalNoiseType

        self.openSimplex2Seed = openSimplex2Seed
        self.openSimplex2Noise2Variant = openSimplex2Noise2Variant
        self.openSimplex2Noise3Variant = openSimplex2Noise3Variant
        self.openSimplex2Noise4Variant = openSimplex2Noise4Variant

        self.voronoiSeed = voronoiSeed
        self.voronoiDistanceFunction = voronoiDistanceFunction
        self.voronoiReturnType = voronoiReturnType
        self.voronoiJitter = voronoiJitter
        self.voronoiMinkowskiP = voronoiMinkowskiP
    }
}
