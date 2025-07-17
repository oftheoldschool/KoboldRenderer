struct StructLayout: Equatable {
    let name: String
    let items: [StructItem]

    func toMetalShaderStruct() -> String {
        return
"""
struct \(name) {
\(items.map { item in
    "    \(item.toMetalShaderDeclaration());"
}.joined(separator: "\n"))
};
"""
    }
}

struct StructItem: Equatable {
    let name: String
    let type: StructItemType
    let attributes: [StructItemAttribute]

    init(
        name: String,
        type: StructItemType,
        attributes: [StructItemAttribute] = []
    ) {
        self.name = name
        self.type = type
        self.attributes = attributes
    }

    func toMetalShaderDeclaration() -> String {
        switch type {
        case .primitive(let primitiveType):
            "\(primitiveType) \(name)"
            + (attributes.isEmpty ? "" : " [[\(attributes.map { $0.description }.joined(separator: ", "))]]")
        case .repeated(let repeatedType):
            "REPEAT(\(repeatedType.count), DECLARE_VAR, \(repeatedType.type), \(name))"
        case .custom(let customType):
            "\(customType) \(name)"
        }
    }
}

enum StructItemAttribute: CustomStringConvertible, Equatable {
    case position
    case color(Int)

    var description: String {
        switch self {
        case .position:
            return "position"
        case .color(let index):
            return "color(\(index))"
        }
    }
}

indirect enum StructItemType: Equatable {
    case primitive(MetalPrimitiveType)
    case repeated(RepeatedItemType)
    case custom(String)
}

struct RepeatedItemType: Equatable {
    let count: String
    let type: MetalPrimitiveType
}

