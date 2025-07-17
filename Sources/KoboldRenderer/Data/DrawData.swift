struct DrawData {
    let model: String
    let pipeline: String
    let instanceCount: Int
    var perObjectBufferBindings: [KBufferBindingType: GPUData]
    let drawFirst: Bool

    public init(
        model: String,
        pipeline: String,
        instanceCount: Int,
        perObjectBufferBindings: [KBufferBindingType: GPUData],
        drawFirst: Bool
    ) {
        self.model = model
        self.pipeline = pipeline
        self.instanceCount = instanceCount
        self.perObjectBufferBindings = perObjectBufferBindings
        self.drawFirst = drawFirst
    }
}
