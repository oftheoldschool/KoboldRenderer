public struct KROccluder {
    let position: SIMD3<Float>
    let radius: Float
    let penumbraFactor: Float
    let sharpness: Float

    public init(
        position: SIMD3<Float>,
        radius: Float,
        penumbraFactor: Float,
        sharpness: Float
    ) {
        self.position = position
        self.radius = radius
        self.penumbraFactor = penumbraFactor
        self.sharpness = sharpness
    }

    func toOccluderUniforms() -> OccluderUniforms {
        return OccluderUniforms(
            position: position,
            radius: radius,
            penumbraFactor: penumbraFactor,
            sharpness: sharpness)
    }
}
