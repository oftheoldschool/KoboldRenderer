import simd

public struct KRDrawInstanceData {
    let model: float4x4
    let normalMatrix: float3x3
    let materialId: Int32

    public init(
        model: float4x4,
        normalMatrix: float3x3,
        materialId: Int32,
    ) {
        self.model = model
        self.normalMatrix = normalMatrix
        self.materialId = materialId
    }
}

public struct KRDrawData {
    let instanceData: [KRDrawInstanceData]
    let model: String
    let pipeline: String
    let instanceKey: String?
    let instanceCount: Int
    let drawFirst: Bool
    let hasTransparency: Bool
    let pose: [float4x4]
    let inverseBindPose: [float4x4]

    public init(
        instanceData: [KRDrawInstanceData],
        model: String,
        pipeline: String,
        instanceCount: Int,
        instanceKey: String? = nil,
        drawFirst: Bool,
        hasTransparency: Bool,
        pose: [float4x4] = [],
        inverseBindPose: [float4x4] = []
    ) {
        self.instanceData = instanceData
        self.model = model
        self.pipeline = pipeline
        self.instanceCount = instanceCount
        self.drawFirst = drawFirst
        self.hasTransparency = hasTransparency
        self.pose = pose
        self.inverseBindPose = inverseBindPose
        self.instanceKey = instanceKey
    }
}
