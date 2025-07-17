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

struct MaterialUniforms {
    let color: SIMD4<Float>
    let materialType: MaterialUniformsType
    let flatShadingMode: FlatShadingMode
    let applyLight: Bool
}
