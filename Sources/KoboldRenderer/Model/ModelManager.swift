import Metal

class ModelManager {
    let device: MTLDevice
    let gpuDataManager: GPUDataManager
    var models: [String: KModel]

    init(
        device: MTLDevice,
        gpuDataManager: GPUDataManager
    ) {
        self.device = device
        self.gpuDataManager = gpuDataManager
        self.models = [:]
    }

    func loadModel(modelInput: KRModelInput) {
        let textures: [String: TextureData] = modelInput.textures.reduce(into: [:]) { acc, next in
            if case let .raw(imageData, sampler) = next.value {
                let texture = createTexture(
                    device: device,
                    pixelFormat: .rgba8Unorm,
                    width: imageData.width,
                    height: imageData.height,
                    source: imageData.data)
                let sampler = createSampler(
                    device: device,
                    modelSampler: sampler)
                acc[next.key] = TextureData(
                    texture: texture,
                    sampler: sampler)
            } else if case let .gpu(texture, sampler) = next.value {
                acc[next.key] = TextureData(texture: texture, sampler: sampler)
            }
        }

        let model = KModel(
            name: modelInput.name,
            meshes: modelInput.meshInput.map { mesh in
                MultiBufferMesh(
                    gpuDataManager: gpuDataManager,
                    verticesData: mesh.verticesData,
                    vertexCount: mesh.vertexCount,
                    indexData: mesh.indexData,
                    indexCount: mesh.indexCount,
                    textures: mesh.textures,
                    primitiveType: mapPrimitiveType(mesh.primitiveType))
            },
            textures: textures
        )
        models[modelInput.name] = model
    }

    private func mapPrimitiveType(_ primitiveType: KRModelPrimitiveType) -> KPrimitiveType {
        return switch primitiveType {
        case .point: .point
        case .line: .line
        case .lineStrip: .lineStrip
        case .triangle: .triangle
        case .triangleStrip: .triangleStrip
        }
    }
}

func createTexture(
    device: MTLDevice,
    pixelFormat: MTLPixelFormat,
    width: Int,
    height: Int,
    source: [UInt8]
) -> MTLTexture {
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: pixelFormat,
        width: width,
        height: height,
        mipmapped: false)
    // todo: add mip map later. Recall that this requires run time generation with an encoder
    //    textureDescriptor.mipmapLevelCount = 4
    textureDescriptor.usage = .shaderRead
    let texture = device.makeTexture(descriptor: textureDescriptor)!

    let region = MTLRegionMake2D(0, 0, width, height)
    texture.replace(
        region: region,
        mipmapLevel: 0,
        withBytes: source,
        bytesPerRow: 4 * width)

    return texture
}

func createSampler(
    device: MTLDevice,
    modelSampler: KModelSampler
) -> MTLSamplerState {
    let samplerStateDescriptor = MTLSamplerDescriptor()

    switch modelSampler.magFilter {
    case .linear:
        samplerStateDescriptor.magFilter = .linear
    case .nearest:
        samplerStateDescriptor.magFilter = .nearest
    case .none: break
    }

    switch modelSampler.minFilter {
    case .linear:
        samplerStateDescriptor.minFilter = .linear
    case .nearest:
        samplerStateDescriptor.minFilter = .nearest
    case .linearMipMapLinear:
        samplerStateDescriptor.minFilter = .linear
        samplerStateDescriptor.mipFilter = .linear
    case .linearMipMapNearest:
        samplerStateDescriptor.minFilter = .linear
        samplerStateDescriptor.mipFilter = .nearest
    case .nearestMipMapLinear:
        samplerStateDescriptor.minFilter = .nearest
        samplerStateDescriptor.mipFilter = .linear
    case .nearestMipMapNearest:
        samplerStateDescriptor.minFilter = .nearest
        samplerStateDescriptor.mipFilter = .nearest
    case .none: break
    }

    switch modelSampler.wrapS {
    case .clampToEdge: samplerStateDescriptor.sAddressMode = .clampToEdge
    case .mirroredRepeat: samplerStateDescriptor.sAddressMode = .mirrorRepeat
    case .standardRepeat: samplerStateDescriptor.sAddressMode = .repeat
    case .none: break
    }

    switch modelSampler.wrapT {
    case .clampToEdge: samplerStateDescriptor.tAddressMode = .clampToEdge
    case .mirroredRepeat: samplerStateDescriptor.tAddressMode = .mirrorRepeat
    case .standardRepeat: samplerStateDescriptor.tAddressMode = .repeat
    case .none: break
    }

    samplerStateDescriptor.normalizedCoordinates = true

    return device.makeSamplerState(descriptor: samplerStateDescriptor)!
}


