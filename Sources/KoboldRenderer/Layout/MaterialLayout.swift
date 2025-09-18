public struct MaterialLayout {
    public let name: String
    public let textureLayoutBindings: [TextureLayoutBinding]

    public init(
        name: String,
        textureLayoutBindings: [TextureLayoutBinding]
    ) {
        self.name = name
        self.textureLayoutBindings = textureLayoutBindings
    }
}
