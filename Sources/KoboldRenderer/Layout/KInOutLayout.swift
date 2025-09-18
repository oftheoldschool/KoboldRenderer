public enum KInOutLayout: Equatable, Sendable {
    case primitive(KMetalVertexPrimitiveType)
    case compound(KStructLayout)

    public var name: String {
        get {
            switch self {
            case .primitive(let type):
                return type.description
            case .compound(let layout):
                return layout.name
            }
        }
    }
}
