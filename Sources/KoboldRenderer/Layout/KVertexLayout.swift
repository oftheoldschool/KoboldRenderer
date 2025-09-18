import Metal

public struct KVertexLayout: Equatable, Sendable {
    public let name: String
    public let attributes: [KVertexAttributeLayout]

    public init(name: String, attributes: [KVertexAttributeLayout]) {
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

public struct KVertexAttributeLayout: Equatable, Sendable {
    public let binding: KBufferLayoutBinding
    public let type: KMetalVertexPrimitiveType
    public let offset: Int

    public init(
        binding: KBufferLayoutBinding,
        type: KMetalVertexPrimitiveType,
        offset: Int
    ) {
        self.binding = binding
        self.type = type
        self.offset = offset
    }
}
