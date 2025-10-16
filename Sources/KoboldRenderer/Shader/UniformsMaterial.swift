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

    let noiseScale: Float
    let noiseOctaves: Int32
    let noisePersistence: Float
    let noiseLacunarity: Float
    let noiseOffset: SIMD3<Float>
    let noiseColorA: SIMD4<Float>
    let noiseColorB: SIMD4<Float>
    let noiseThreshold: Float
    let varyWithTime: Bool

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

        self.noiseScale = 1.0
        self.noiseOctaves = 4
        self.noisePersistence = 0.5
        self.noiseLacunarity = 2.0
        self.noiseOffset = SIMD3<Float>(0.0, 0.0, 0.0)
        self.noiseColorA = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
        self.noiseColorB = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
        self.noiseThreshold = 0.0
        self.varyWithTime = false
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
        noiseScale: Float,
        noiseOctaves: Int32,
        noisePersistence: Float,
        noiseLacunarity: Float,
        noiseOffset: SIMD3<Float>,
        noiseColorA: SIMD4<Float>,
        noiseColorB: SIMD4<Float>,
        noiseThreshold: Float,
        varyWithTime: Bool
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
        self.noiseScale = noiseScale
        self.noiseOctaves = noiseOctaves
        self.noisePersistence = noisePersistence
        self.noiseLacunarity = noiseLacunarity
        self.noiseOffset = noiseOffset
        self.noiseColorA = noiseColorA
        self.noiseColorB = noiseColorB
        self.noiseThreshold = noiseThreshold
        self.varyWithTime = varyWithTime
    }
}
