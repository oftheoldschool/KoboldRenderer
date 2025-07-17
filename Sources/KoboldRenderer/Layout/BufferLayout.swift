public enum KBufferBindingType {
    case attributePosition
    case attributeNormal
    case attributeTexCoords
    case attributeWeights
    case attributeJoints
    case uniformsShared
    case uniformsLights
    case uniformsObject
    case uniformsLightSpaceVolumes
    case uniformsCascadeFrustumLimitsClipSpace
    case uniformsAnimationPose
    case uniformsAnimationInverseBindPose
    case materials
}

struct BufferLayoutBinding: Equatable {
    let index: Int
    let type: KBufferBindingType
    let repeated: Bool

    init(
        index: Int,
        type: KBufferBindingType,
        repeated: Bool = false
    ) {
        self.index = index
        self.type = type
        self.repeated = repeated
    }
}

struct BufferLayout {
    let bufferLayoutBindings: [BufferLayoutBinding]
}

indirect enum BufferDataType: Equatable, CustomStringConvertible {
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

extension KBufferBindingType: CustomStringConvertible {
    public var description: String {
        return switch self {
        case .attributePosition: "position"
        case .attributeNormal: "normal"
        case .attributeTexCoords: "texCoords"
        case .attributeWeights: "weights"
        case .attributeJoints: "joints"
        case .uniformsShared: "uniformsShared"
        case .uniformsLights: "uniformsLights"
        case .uniformsObject: "uniformsObject"
        case .uniformsLightSpaceVolumes: "uniformsLightSpaceVolumes"
        case .uniformsCascadeFrustumLimitsClipSpace: "uniformsCascadeEndClipSpace"
        case .uniformsAnimationPose: "uniformsAnimationPose"
        case .uniformsAnimationInverseBindPose: "uniformsAnimationInverseBindPose"
        case .materials: "materials"
        }
    }
}

extension KBufferBindingType {
    public var isAttribute: Bool {
        return [
            .attributePosition,
            .attributeNormal,
            .attributeTexCoords,
            .attributeWeights,
            .attributeNormal,
        ].contains(self)
    }

    var datatype: BufferDataType {
        return switch self {
        case .attributePosition: .primitive(.float3)
        case .attributeNormal: .primitive(.float3)
        case .attributeTexCoords: .primitive(.float2)
        case .attributeWeights: .primitive(.float4)
        case .attributeJoints: .primitive(.int4)
        case .uniformsShared: .custom("SharedUniforms")
        case .uniformsLights: .pointer(.custom("LightUniforms"))
        case .uniformsObject: .custom("DrawObjectUniforms")
        case .uniformsLightSpaceVolumes: .pointer(.primitive(.float4x4))
        case .uniformsCascadeFrustumLimitsClipSpace: .pointer(.primitive(.float))
        case .uniformsAnimationPose: .pointer(.primitive(.float4x4))
        case .uniformsAnimationInverseBindPose: .pointer(.primitive(.float4x4))
        case .materials: .pointer(.custom("MaterialUniforms"))
        }
    }
}
