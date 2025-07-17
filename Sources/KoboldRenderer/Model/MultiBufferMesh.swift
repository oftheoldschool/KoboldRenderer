import simd
import Metal

public enum KIndexType {
    case uint16
    case uint32
}

extension KIndexType {
    func toMetalIndexType() -> MTLIndexType {
        switch self {
        case .uint16:
            return .uint16
        case .uint32:
            return .uint32
        }
    }
}

struct IndexBuffer {
    let indexBuffer: GPUDataBuffer?
    let indexBufferType: KIndexType
    let indexCount: Int
}

struct AttributesBuffer {
    let buffers: [KBufferBindingType: GPUDataBuffer]
    let vertexCount: Int
}

struct MultiBufferMesh {
    let attributes: AttributesBuffer
    let indices: IndexBuffer?
    let textures: [KTextureBindingType: String]

    init(
        gpuDataManager: GPUDataManager,
        verticesData: [(type: KBufferBindingType, size: Int, data: [UInt8])],
        vertexCount: Int,
        indexData: (type: KIndexType, size: Int, data: [UInt8]),
        indexCount: Int,
        textures: [KTextureBindingType: String] = [:]
    ) {
        let indexDataSize = indexData.data.count
        let bufferSizes: [Int] = verticesData.reduce([indexDataSize]) { acc, next in
            return acc + [next.data.count]
        }
        let buffers = gpuDataManager.newBufferChunks(bufferSizes)

        buffers[0].copy(data: indexData.data)

        for (i, vertices) in verticesData.enumerated() {
            buffers[i + 1].copy(data: vertices.data)
        }

        self.indices = IndexBuffer(
            indexBuffer: buffers[0],
            indexBufferType: indexData.type,
            indexCount: indexCount)

        self.attributes = AttributesBuffer(
            buffers: Dictionary(uniqueKeysWithValues: verticesData.enumerated().map { (i, vertices) in
                (vertices.type, buffers[i + 1])
            }),
            vertexCount: vertexCount)

        self.textures = textures
    }
}
