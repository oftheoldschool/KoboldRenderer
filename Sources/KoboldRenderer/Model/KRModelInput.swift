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
    public let boundingBox: KBoundingBox

    public init(
        name: String,
        meshInput: [KMeshInput],
        textures: [String: KModelTexture]
    ) {
        self.name = name
        self.meshInput = meshInput
        self.textures = textures
        self.boundingBox = KBoundingBox(meshInput.map { $0.boundingBox })
    }
}

public struct KBoundingBox {
    public let min: SIMD3<Float>
    public let max: SIMD3<Float>

    public init(min: SIMD3<Float>, max: SIMD3<Float>) {
        self.min = min
        self.max = max
    }

    public init(_ data: [SIMD3<Float>]) {
        (self.min, self.max) = data.reduce((min: SIMD3<Float>.zero, max: SIMD3<Float>.zero)) { acc, next in
            (Self.minSIMD3(acc.min, next), max: Self.maxSIMD3(acc.max, next))
        }
    }

    public init(_ data: [KBoundingBox]) {
        (self.min, self.max) = data.reduce((min: SIMD3<Float>.zero, max: SIMD3<Float>.zero)) { acc, next in
            (Self.minSIMD3(acc.min, next.min), max: Self.maxSIMD3(acc.max, next.max))
        }
    }

    private static func minSIMD3(_ lhs: SIMD3<Float>, _ rhs: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(
            Swift.min(lhs.x, rhs.x),
            Swift.min(lhs.y, rhs.y),
            Swift.min(lhs.z, rhs.z))
    }

    private static func maxSIMD3(_ lhs: SIMD3<Float>, _ rhs: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(
            Swift.max(lhs.x, rhs.x),
            Swift.max(lhs.y, rhs.y),
            Swift.max(lhs.z, rhs.z))
    }
}

public struct KMeshInput {
    public let verticesData: [(KBufferBindingType, Int, [UInt8])]
    public let vertexCount: Int

    public let boundingBox: KBoundingBox

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
        primitiveType: KRModelPrimitiveType,
        boundingBox: KBoundingBox
    ) {
        self.verticesData = verticesData
        self.vertexCount = vertexCount
        self.indexData = indexData
        self.indexCount = indexCount
        self.textures = textures
        self.primitiveType = primitiveType
        self.boundingBox = boundingBox
    }
}
