import Metal

public enum GPUData {
    case wrapper(GPUDataWrapper)
    case buffer(GPUDataBuffer)
}

public struct GPUDataWrapper {
    let data: [UInt8]
    let length: Int

    public init(data: [UInt8], length: Int) {
        self.data = data
        self.length = length
    }

    public init<T>(_ value: T) {
        var byteArray = [UInt8]()
        withUnsafeBytes(of: value) { rawBufferPointer in
            byteArray = Array(rawBufferPointer)
        }
        self.data = byteArray
        self.length = MemoryLayout<T>.stride
    }

    public init<T>(_ values: [T]) {
        var byteArray = [UInt8]()
        values.withUnsafeBytes { rawBufferPointer in
            byteArray = Array(rawBufferPointer)
        }
        self.data = byteArray
        self.length = MemoryLayout<T>.stride * values.count
    }
}

public struct GPUDataBuffer {
    let buffer: MTLBuffer
    var offset: Int
    var length: Int

    public init(buffer: MTLBuffer, offset: Int, length: Int) {
        self.buffer = buffer
        self.offset = offset
        self.length = length
    }

    public func copy<T>(data: [T]) {
        let memoryPointer = buffer.contents().advanced(by: offset)
        let _ = data.withUnsafeBytes { rawBufferPointer in
            memcpy(memoryPointer, rawBufferPointer.baseAddress!, min(length, rawBufferPointer.count))
        }
    }

    public func copy<T>(data: T) {
        let memoryPointer = buffer.contents().advanced(by: offset)
        let _ = withUnsafeBytes(of: data) { rawBufferPointer in
            memcpy(memoryPointer, rawBufferPointer.baseAddress!, min(length, rawBufferPointer.count))
        }
    }

    public func extract<T>(count: Int, offset: Int = 0) -> [T] {
        let memoryPointer = buffer.contents().advanced(by: offset)
        let typedPointer = memoryPointer.bindMemory(to: T.self, capacity: MemoryLayout<T>.stride * count)
        let bufferedPointer = UnsafeBufferPointer(start: typedPointer, count: count)
        return Array(bufferedPointer)
    }
}

public class GPUDataMultiBuffer {
    let bufferArray: [GPUDataBuffer]

    public init(gpuDataManager: GPUDataManager, count: Int, length: Int) {
        self.bufferArray = gpuDataManager.newBufferArray(count: count, sizeBytes: length)
    }

    public subscript(index: Int) -> GPUDataBuffer! {
        get {
            return self.bufferArray[index]
        }
    }
}
