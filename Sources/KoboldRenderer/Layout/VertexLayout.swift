import Metal

struct VertexLayout: Equatable {
    let name: String
    let attributes: [VertexAttributeLayout]

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

struct VertexAttributeLayout: Equatable {
    let binding: BufferLayoutBinding
    let type: MetalVertexPrimitiveType
    let offset: Int
}
