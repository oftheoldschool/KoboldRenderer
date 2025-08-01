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
    let color: SIMD4<Float>
    let ambientFactor: Float
    let shininess: Float
    let specularIntensity: Float
    let rimIntensity: Float
    let rimColor: SIMD3<Float>
    let rimPower: Float
    let materialType: MaterialUniformsType
    let flatShadingMode: FlatShadingMode
    let rimLightingMode: RimLightingMode
    let applyLight: Bool
    let receiveShadow: Bool
}
