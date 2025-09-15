public struct KBufferBindingType: CustomStringConvertible, Hashable {
    let name: String
    public let description: String
    let datatype: BufferDataType
    let isAttribute: Bool
    let bindingIndex: Int

    public init(
        name: String,
        description: String,
        datatype: BufferDataType,
        isAttribute: Bool,
        bindingIndex: Int
    ) {
        self.name = name
        self.description = description
        self.datatype = datatype
        self.isAttribute = isAttribute
        self.bindingIndex = bindingIndex
    }
}

public extension KBufferBindingType {
    static let attributePosition: KBufferBindingType = KBufferBindingType(
        name: "attributePosition",
        description: "position",
        datatype: .primitive(.float3),
        isAttribute: true,
        bindingIndex: 0
    )

    static let attributeNormal: KBufferBindingType = KBufferBindingType(
        name: "attributeNormal",
        description: "normal",
        datatype: .primitive(.float3),
        isAttribute: true,
        bindingIndex: 1
    )

    static let attributeTexCoords: KBufferBindingType = KBufferBindingType(
        name: "attributeTexCoords",
        description: "texCoords",
        datatype: .primitive(.float2),
        isAttribute: true,
        bindingIndex: 2
    )

    static let attributeWeights: KBufferBindingType = KBufferBindingType(
        name: "attributeWeights",
        description: "weights",
        datatype: .primitive(.float4),
        isAttribute: true,
        bindingIndex: 3
    )

    static let attributeJoints: KBufferBindingType = KBufferBindingType(
        name: "attributeJoints",
        description: "joints",
        datatype: .primitive(.int4),
        isAttribute: true,
        bindingIndex: 4
    )

    static let uniformsShared: KBufferBindingType = KBufferBindingType(
        name: "uniformsShared",
        description: "uniformsShared",
        datatype: .custom("SharedUniforms"),
        isAttribute: false,
        bindingIndex: 5
    )

    static let uniformsLights: KBufferBindingType = KBufferBindingType(
        name: "uniformsLights",
        description: "uniformsLights",
        datatype: .pointer(.custom("LightUniforms")),
        isAttribute: false,
        bindingIndex: 6
    )

    static let uniformsObject: KBufferBindingType = KBufferBindingType(
        name: "uniformsObject",
        description: "uniformsObject",
        datatype: .custom("DrawObjectUniforms"),
        isAttribute: false,
        bindingIndex: 7
    )

    static let uniformsLightSpaceVolumes: KBufferBindingType = KBufferBindingType(
        name: "uniformsLightSpaceVolumes",
        description: "uniformsLightSpaceVolumes",
        datatype: .pointer(.primitive(.float4x4)),
        isAttribute: false,
        bindingIndex: 8
    )

    static let uniformsCascadeFrustumLimitsClipSpace: KBufferBindingType = KBufferBindingType(
        name: "uniformsCascadeFrustumLimitsClipSpace",
        description: "uniformsCascadeEndClipSpace",
        datatype: .pointer(.primitive(.float)),
        isAttribute: false,
        bindingIndex: 9
    )

    static let uniformsAnimationPose: KBufferBindingType = KBufferBindingType(
        name: "uniformsAnimationPose",
        description: "uniformsAnimationPose",
        datatype: .pointer(.primitive(.float4x4)),
        isAttribute: false,
        bindingIndex: 10
    )

    static let uniformsAnimationInverseBindPose: KBufferBindingType = KBufferBindingType(
        name: "uniformsAnimationInverseBindPose",
        description: "uniformsAnimationInverseBindPose",
        datatype: .pointer(.primitive(.float4x4)),
        isAttribute: false,
        bindingIndex: 11
    )

    static let materials: KBufferBindingType = KBufferBindingType(
        name: "materials",
        description: "materials",
        datatype: .pointer(.custom("MaterialUniforms")),
        isAttribute: false,
        bindingIndex: 12
    )
}

public struct BufferLayoutBinding: Equatable {
    let index: Int
    let type: KBufferBindingType
    let repeated: Bool

    public init(
        index: Int,
        type: KBufferBindingType,
        repeated: Bool = false
    ) {
        self.index = index
        self.type = type
        self.repeated = repeated
    }

}

public struct BufferLayout {
    let name: String
    let bufferLayoutBindings: [BufferLayoutBinding]

    public init(
        name: String,
        bufferLayoutBindings: [BufferLayoutBinding]
    ) {
        self.name = name
        self.bufferLayoutBindings = bufferLayoutBindings
    }
}

indirect public enum BufferDataType: Hashable, Equatable, CustomStringConvertible {
    case primitive(MetalPrimitiveType)
    case pointer(BufferDataType)
    case custom(String)

    public var description: String {
        switch self {
        case .primitive(let primitive): primitive.description
        case .pointer(let pointee): pointee.description
        case .custom(let custom): custom
        }
    }
}




