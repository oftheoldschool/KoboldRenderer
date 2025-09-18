public struct StructLayout: Equatable {
    public let name: String
    public let items: [StructItem]

    public init(
        name: String,
        items: [StructItem]
    ) {
        self.name = name
        self.items = items
    }

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

public struct StructItem: Equatable {
    public let name: String
    public let type: StructItemType
    public let attributes: [StructItemAttribute]

    public init(
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

public enum StructItemAttribute: CustomStringConvertible, Equatable {
    case position
    case color(Int)

    public var description: String {
        switch self {
        case .position:
            return "position"
        case .color(let index):
            return "color(\(index))"
        }
    }
}

indirect public enum StructItemType: Equatable {
    case primitive(MetalPrimitiveType)
    case repeated(RepeatedItemType)
    case custom(String)
}

public struct RepeatedItemType: Equatable {
    public let count: String
    public let type: MetalPrimitiveType

    public init(
        count: String,
        type: MetalPrimitiveType
    ) {
        self.count = count
        self.type = type
    }
}
