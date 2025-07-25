import Metal

public enum KModelTexture {
    case gpu(texture: MTLTexture, sampler: MTLSamplerState)
    case raw(imageData: KImageData, sampler: KModelSampler)
}

public struct KModelSampler {
    public enum KSamplerMagFilter {
        case nearest
        case linear
    }

    public enum KSamplerMinFilter {
        case nearest
        case linear
        case nearestMipMapNearest
        case linearMipMapNearest
        case nearestMipMapLinear
        case linearMipMapLinear
    }

    public enum KSamplerWrap {
        case clampToEdge
        case mirroredRepeat
        case standardRepeat
    }

    public let minFilter: KSamplerMinFilter?
    public let magFilter: KSamplerMagFilter?
    public let wrapS: KSamplerWrap?
    public let wrapT: KSamplerWrap?

    public init(
        minFilter: KSamplerMinFilter?,
        magFilter: KSamplerMagFilter?,
        wrapS: KSamplerWrap?,
        wrapT: KSamplerWrap?
    ) {
        self.minFilter = minFilter
        self.magFilter = magFilter
        self.wrapS = wrapS
        self.wrapT = wrapT
    }
}

public enum KRModelPrimitiveType {
    case point
    case line
    case lineStrip
    case triangle
    case triangleStrip
}

public struct KRModelInput {
    public let name: String
    public let meshInput: [KMeshInput]
    public let textures: [String: KModelTexture]

    public init(
        name: String,
        meshInput: [KMeshInput],
        textures: [String: KModelTexture]
    ) {
        self.name = name
        self.meshInput = meshInput
        self.textures = textures
    }
}

public struct KMeshInput {
    public let verticesData: [(KBufferBindingType, Int, [UInt8])]
    public let vertexCount: Int

    public let indexData: (KIndexType, Int, [UInt8])
    public let indexCount: Int

    public let primitiveType: KRModelPrimitiveType

    public let textures: [KTextureBindingType: String]

    public init(
        verticesData: [(KBufferBindingType, Int, [UInt8])],
        vertexCount: Int,
        indexData: (KIndexType, Int, [UInt8]),
        indexCount: Int,
        textures: [KTextureBindingType : String],
        primitiveType: KRModelPrimitiveType
    ) {
        self.verticesData = verticesData
        self.vertexCount = vertexCount
        self.indexData = indexData
        self.indexCount = indexCount
        self.textures = textures
        self.primitiveType = primitiveType
    }
}
