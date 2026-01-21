import Metal

public class GPUDataManager {
    public static let defaultPadding = 256

    let device: MTLDevice

    public init(device: MTLDevice) {
        self.device = device
    }

    public func newBuffer(length: Int, padding: Int = defaultPadding) -> GPUDataBuffer {
        let paddedLength = length + (padding > 0 ? (padding - length % padding) : 0)
        return GPUDataBuffer(
            buffer: device.makeBuffer(length: paddedLength)!,
            offset: 0,
            length: length)
    }

    public func newBufferChunks(_ sizesBytes: Int..., padding: Int = defaultPadding) -> [GPUDataBuffer] {
        return newBufferChunks(Array(sizesBytes), padding: padding)
    }

    public func newBufferArray(count: Int, sizeBytes: Int, padding: Int = defaultPadding) -> [GPUDataBuffer] {
        return newBufferChunksArray(count: count, sizesBytes: [sizeBytes], padding: padding).map { $0[0] }
    }

    public func newBufferChunks(_ sizesBytes: [Int], padding: Int = defaultPadding) -> [GPUDataBuffer] {
        return newBufferChunksArray(count: 1, sizesBytes: sizesBytes, padding: padding)[0]
    }

    public func newBufferChunksArray(count: Int, sizesBytes: Int..., padding: Int = defaultPadding) -> [[GPUDataBuffer]] {
        return newBufferChunksArray(count: count, sizesBytes: sizesBytes, padding: padding)
    }

    public func newBufferChunksArray(count: Int, sizesBytes: [Int], padding: Int = defaultPadding) -> [[GPUDataBuffer]] {
        let paddedSizesBytes = sizesBytes.map { sizeBytes in
            (sizeBytes, sizeBytes + (padding > 0 ? (padding - sizeBytes % padding) : 0))
        }

        let totalBufferSizeBytes: Int = paddedSizesBytes.reduce(0) { $0 + $1.1 }
        let mtlBuffer = device.makeBuffer(length: totalBufferSizeBytes * count)!

        return (0..<count).map { i in
            var offset = 0
            return paddedSizesBytes.map { (sizeBytes, paddedSizeBytes) in
                let buffer = GPUDataBuffer(
                    buffer: mtlBuffer,
                    offset: i * totalBufferSizeBytes + offset,
                    length: sizeBytes)
                offset += paddedSizeBytes
                return buffer
            }
        }
    }
}

