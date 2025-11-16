struct OccluderUniforms {
    public let position: SIMD3<Float>
    public let radius: Float
    public let penumbraFactor: Float
    public let sharpness: Float

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
}
