public struct KStructLayout: Equatable, Sendable {
    public let name: String
    public let items: [KStructItem]

    public init(
        name: String,
        items: [KStructItem]
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

public struct KStructItem: Equatable, Sendable {
    public let name: String
    public let type: KStructItemType
    public let attributes: [KStructItemAttribute]

    public init(
        name: String,
        type: KStructItemType,
        attributes: [KStructItemAttribute] = []
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

public enum KStructItemAttribute: CustomStringConvertible, Equatable, Sendable {
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

indirect public enum KStructItemType: Equatable, Sendable {
    case primitive(KMetalPrimitiveType)
    case repeated(KRepeatedItemType)
    case custom(String)
}

public struct KRepeatedItemType: Equatable, Sendable {
    public let count: String
    public let type: KMetalPrimitiveType

    public init(
        count: String,
        type: KMetalPrimitiveType
    ) {
        self.count = count
        self.type = type
    }
}
