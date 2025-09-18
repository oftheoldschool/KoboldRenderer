public enum KTextureBindingType {
    case textureBaseColor
    case textureCubeMap
    case textureArrayCascadedShadowMap
    case texturePassThrough
    case textureGBufferNormals
    case textureGBufferAlbedos
    case textureGBufferDepth
    case textureCombineColor
    case textureCombineBrightness
    case textureCombineColorAlpha
    case textureCombineBrightnessAlpha
    case textureCombineRevealage
    case textureComputeInput
    case textureComputeOutput
    case textureComputeBloomOutput

}

public struct TextureLayout {
    public let name: String
    public let textureLayoutBindings: [TextureLayoutBinding]

    public init(
        name: String,
        textureLayoutBindings: [TextureLayoutBinding]
    ) {
        self.name = name
        self.textureLayoutBindings = textureLayoutBindings
    }
}

indirect enum TextureDataType: CustomStringConvertible {
    case texture2d
    case depth2d
    case cube
    case array(TextureDataType)

    public var description: String {
        switch self {
        case .texture2d: "texture2d"
        case .depth2d: "depth2d"
        case .cube: "texturecube"
        case .array(let type): type.description + "_array"
        }
    }
}

public enum TextureAccessType: CustomStringConvertible {
    case sample
    case read
    case write

    public var description: String {
        switch self {
        case .sample: "sample"
        case .read: "read"
        case .write: "write"
        }
    }
}

public struct TextureLayoutBinding: Equatable {
    public let index: Int
    public let type: KTextureBindingType
    public let accessType: TextureAccessType

    public init(
        index: Int,
        type: KTextureBindingType,
        accessType: TextureAccessType
    ) {
        self.index = index
        self.type = type
        self.accessType = accessType
    }
}


extension KTextureBindingType: CustomStringConvertible {
    public var description: String {
        return switch self {
        case .textureArrayCascadedShadowMap: "textureArrayCascadedShadowMap"
        case .textureBaseColor: "textureBaseColor"
        case .textureCubeMap: "textureCubeMap"
        case .texturePassThrough: "texturePassThrough"
        case .textureGBufferDepth: "textureGBufferDepth"
        case .textureGBufferNormals: "textureGBufferNormals"
        case .textureGBufferAlbedos: "textureGBufferAlbedos"
        case .textureComputeInput: "textureComputeInput"
        case .textureComputeOutput: "textureComputeOutput"
        case .textureComputeBloomOutput: "textureComputeBloomOutput"
        case .textureCombineColor: "textureCombineColor"
        case .textureCombineBrightness: "textureCombineBrightness"
        case .textureCombineColorAlpha: "textureCombineColorAlpha"
        case .textureCombineBrightnessAlpha: "textureCombineBrightnessAlpha"
        case .textureCombineRevealage: "textureCombineRevealage"
        }
    }
}

extension KTextureBindingType {
    var primitiveType: MetalPrimitiveType {
        return switch self {
        case .textureArrayCascadedShadowMap: .float
        case .textureCubeMap: .float
        case .textureBaseColor: .float
        case .texturePassThrough: .float
        case .textureGBufferDepth: .float
        case .textureGBufferNormals: .float
        case .textureGBufferAlbedos: .float
        case .textureComputeInput: .float
        case .textureComputeOutput: .float
        case .textureComputeBloomOutput: .float
        case .textureCombineColor: .float
        case .textureCombineBrightness: .float
        case .textureCombineColorAlpha: .float
        case .textureCombineBrightnessAlpha: .float
        case .textureCombineRevealage: .float
        }
    }

    var dataType: TextureDataType {
        return switch self {
        case .textureArrayCascadedShadowMap: .array(.depth2d)
        case .textureCubeMap: .cube
        case .textureBaseColor: .texture2d
        case .texturePassThrough: .texture2d
        case .textureGBufferDepth: .depth2d
        case .textureGBufferNormals: .texture2d
        case .textureGBufferAlbedos: .texture2d
        case .textureComputeInput: .texture2d
        case .textureComputeOutput: .texture2d
        case .textureComputeBloomOutput: .texture2d
        case .textureCombineColor: .texture2d
        case .textureCombineBrightness: .texture2d
        case .textureCombineColorAlpha: .texture2d
        case .textureCombineBrightnessAlpha: .texture2d
        case .textureCombineRevealage: .texture2d
        }
    }
}
