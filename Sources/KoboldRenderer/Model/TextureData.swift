import Metal

public enum GPUTexture {
    case texture(TextureData)
    case textureArray(TextureArrayData)
    case arrayOfTexture(ArrayOfTextureData)
}

public struct TextureData {
    let texture: MTLTexture
    let sampler: MTLSamplerState?

    public init(texture: MTLTexture, sampler: MTLSamplerState?) {
        self.texture = texture
        self.sampler = sampler
    }
}

public struct TextureArrayData {
    let textureArray: MTLTexture
    let sampler: MTLSamplerState?

    public init(textureArray: MTLTexture, sampler: MTLSamplerState?) {
        self.textureArray = textureArray
        self.sampler = sampler
    }
}

public struct ArrayOfTextureData {
    public let texture: [MTLTexture]
    public let sampler: MTLSamplerState?

    public init(texture: [MTLTexture], sampler: MTLSamplerState?) {
        self.texture = texture
        self.sampler = sampler
    }
}
