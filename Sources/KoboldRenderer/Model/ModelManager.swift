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
        self.createDebugBoundingBoxModel()
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
                    boundingBox: mesh.boundingBox,
                    indexData: mesh.indexData,
                    indexCount: mesh.indexCount,
                    textures: mesh.textures,
                    primitiveType: mapPrimitiveType(mesh.primitiveType))
            },
            textures: textures,
            boundingBox: modelInput.boundingBox
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

    private func createDebugBoundingBoxModel() {
        let positions: [SIMD3<Float>] = [
            SIMD3<Float>( 1,  1,  1),
            SIMD3<Float>( 1, -1,  1),
            SIMD3<Float>(-1, -1,  1),
            SIMD3<Float>(-1,  1,  1),
            SIMD3<Float>( 1,  1, -1),
            SIMD3<Float>( 1, -1, -1),
            SIMD3<Float>(-1, -1, -1),
            SIMD3<Float>(-1,  1, -1),
        ]

        let lineIndices: [UInt32] = [
            // Front face
            0, 1, 1, 2, 2, 3, 3, 0,
            // Back face
            4, 5, 5, 6, 6, 7, 7, 4,
            // Connecting edges
            0, 4, 1, 5, 2, 6, 3, 7,
        ]

        let normals: [SIMD3<Float>] = Array(repeating: SIMD3<Float>(0, 1, 0), count: 8)
        let texCoords: [SIMD2<Float>] = Array(repeating: SIMD2<Float>(0, 0), count: 8)

        let modelInput = KRModelInput(
            name: "debugBoundingBox",
            meshInput: [
                KMeshInput(
                    verticesData: [
                        (.attributePosition, MemoryLayout<SIMD3<Float>>.stride, positions.toByteArray()),
                        (.attributeNormal, MemoryLayout<SIMD3<Float>>.stride, normals.toByteArray()),
                        (.attributeTexCoords, MemoryLayout<SIMD2<Float>>.stride, texCoords.toByteArray())
                    ],
                    vertexCount: positions.count,
                    indexData: (.uint32, MemoryLayout<UInt32>.stride, lineIndices.toByteArray()),
                    indexCount: lineIndices.count,
                    textures: [:],
                    primitiveType: .line,
                    boundingBox: KBoundingBox(min: SIMD3<Float>(-1, -1, -1), max: SIMD3<Float>(1, 1, 1))
                )
            ],
            textures: [:]
        )

        loadModel(modelInput: modelInput)
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

