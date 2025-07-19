public struct RenderPipelineDefinition {
    let name: String
    let vertexFunctionName: String
    let fragmentFunctionName: String
    let supportsBloom: Bool
    let supportsAnimation: Bool
    let supportsTransparency: Bool
    let supportsInstancing: Bool

    public init(
        name: String,
        vertexFunctionName: String,
        fragmentFunctionName: String,
        supportsBloom: Bool,
        supportsAnimation: Bool,
        supportsTransparency: Bool,
        supportsInstancing: Bool
    ) {
        self.name = name
        self.vertexFunctionName = vertexFunctionName
        self.fragmentFunctionName = fragmentFunctionName
        self.supportsBloom = supportsBloom
        self.supportsAnimation = supportsAnimation
        self.supportsTransparency = supportsTransparency
        self.supportsInstancing = supportsInstancing
    }
}
