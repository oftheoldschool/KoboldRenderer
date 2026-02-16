struct DrawData {
    let model: String
    let pipeline: String
    let instanceCount: Int
    var perObjectBufferBindings: [KBufferBindingType: GPUData]
    let drawFirst: Bool
    let castsShadow: Bool
    let isOccluder: Bool
    let drawBoundingBox: Bool

    public init(
        model: String,
        pipeline: String,
        instanceCount: Int,
        perObjectBufferBindings: [KBufferBindingType: GPUData],
        drawFirst: Bool,
        castsShadow: Bool,
        isOccluder: Bool,
        drawBoundingBox: Bool
    ) {
        self.model = model
        self.pipeline = pipeline
        self.instanceCount = instanceCount
        self.perObjectBufferBindings = perObjectBufferBindings
        self.drawFirst = drawFirst
        self.castsShadow = castsShadow
        self.isOccluder = isOccluder
        self.drawBoundingBox = drawBoundingBox
    }
}
