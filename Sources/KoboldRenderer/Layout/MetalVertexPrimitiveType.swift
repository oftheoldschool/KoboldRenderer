import Metal

enum MetalVertexPrimitiveType: CustomStringConvertible {
    case float
    case float2
    case float3
    case float4
    case int
    case int2
    case int3
    case int4

    var description: String {
        switch self {
        case .float:
            return "float"
        case .float2:
            return "float2"
        case .float3:
            return "float3"
        case .float4:
            return "float4"
        case .int:
            return "int"
        case .int2:
            return "int2"
        case .int3:
            return "int3"
        case .int4:
            return "int4"
        }
    }

    func toMTLVertexFormat() -> MTLVertexFormat {
        switch self {
        case .float:
            return .float
        case .float2:
            return .float2
        case .float3:
            return .float3
        case .float4:
            return .float4
        case .int:
            return .int
        case .int2:
            return .int2
        case .int3:
            return .int3
        case .int4:
            return .int4
        }
    }

    var stride: Int {
        switch self {
        case .float:
            return MemoryLayout<Float>.size * 1
        case .float2:
            return MemoryLayout<Float>.size * 2
        case .float3:
            return MemoryLayout<Float>.size * 3
        case .float4:
            return MemoryLayout<Float>.size * 4
        case .int:
            return MemoryLayout<Int32>.size * 1
        case .int2:
            return MemoryLayout<Int32>.size * 2
        case .int3:
            return MemoryLayout<Int32>.size * 3
        case .int4:
            return MemoryLayout<Int32>.size * 4
        }
    }
}
