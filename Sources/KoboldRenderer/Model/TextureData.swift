import Metal

enum GPUTexture {
    case texture(TextureData)
    case textureArray(TextureArrayData)
    case arrayOfTexture(ArrayOfTextureData)
}

struct TextureData {
    let texture: MTLTexture
    let sampler: MTLSamplerState?
}

struct TextureArrayData {
    let textureArray: MTLTexture
    let sampler: MTLSamplerState?
}

struct ArrayOfTextureData {
    public let texture: [MTLTexture]
    public let sampler: MTLSamplerState?
}
