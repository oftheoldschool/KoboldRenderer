public struct KMaterialLayout: Sendable {
    public let name: String
    public let textureLayoutBindings: [KTextureLayoutBinding]

    public init(
        name: String,
        textureLayoutBindings: [KTextureLayoutBinding]
    ) {
        self.name = name
        self.textureLayoutBindings = textureLayoutBindings
    }
}
