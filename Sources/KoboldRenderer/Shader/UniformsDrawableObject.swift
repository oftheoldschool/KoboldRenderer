import simd

struct DrawObjectUniforms {
    public let model: float4x4
    public let normalMatrix: float3x3
    public let materialId: Int32
}
