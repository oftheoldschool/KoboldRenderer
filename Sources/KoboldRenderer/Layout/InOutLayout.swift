enum InOutLayout: Equatable {
    case primitive(MetalVertexPrimitiveType)
    case compound(StructLayout)

    var name: String {
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
