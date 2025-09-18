public enum KMetalPrimitiveType: CustomStringConvertible, Sendable {
    case bool
    case uint8_t
    case int32_t
    case int
    case int2
    case int3
    case int4
    case float
    case float2
    case float3
    case float4
    case half
    case float3x3
    case float4x4

    public var description: String {
        return switch self {
        case .bool: "bool"
        case .uint8_t: "uint8_t"
        case .int32_t: "int32_t"
        case .int: "int"
        case .int2: "int2"
        case .int3: "int3"
        case .int4: "int4"
        case .float: "float"
        case .float2: "float2"
        case .float3: "float3"
        case .float4: "float4"
        case .half: "half"
        case .float3x3: "float3x3"
        case .float4x4: "float4x4"
        }
    }
}
