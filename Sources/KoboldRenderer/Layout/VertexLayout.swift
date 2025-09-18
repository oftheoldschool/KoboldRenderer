import Metal

public struct VertexLayout: Equatable {
    public let name: String
    public let attributes: [VertexAttributeLayout]

    public init(name: String, attributes: [VertexAttributeLayout]) {
        self.name = name
        self.attributes = attributes
    }

    func toMetalShaderStruct() -> String {
        return
"""
struct \(name) {
\(attributes.map {
    "    \($0.type) \($0.binding.type)  [[attribute(\($0.binding.index))]];"
}.joined(separator: "\n"))
};
"""
    }
}

public struct VertexAttributeLayout: Equatable {
    public let binding: BufferLayoutBinding
    public let type: MetalVertexPrimitiveType
    public let offset: Int

    public init(
        binding: BufferLayoutBinding,
        type: MetalVertexPrimitiveType,
        offset: Int
    ) {
        self.binding = binding
        self.type = type
        self.offset = offset
    }
}
