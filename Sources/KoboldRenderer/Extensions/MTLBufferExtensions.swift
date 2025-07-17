import Metal

extension MTLBuffer {
    func upload<T>(data: [T], offset: Int = 0) {
        data.withUnsafeBytes { d in
            let memoryPointer = self.contents().advanced(by: offset)

            memoryPointer.copyMemory(
                from: d.baseAddress!, 
                byteCount: MemoryLayout<T>.stride * data.count)
        }
    }

    func download<T>(count: Int, offset: Int = 0) -> [T] {
        let memoryPointer = self.contents().advanced(by: offset)
        
        let typedPointer = memoryPointer.bindMemory(
            to: T.self, 
            capacity: MemoryLayout<T>.stride * count)
        
        let bufferedPointer = UnsafeBufferPointer(
            start: typedPointer, 
            count: count)

        return Array(bufferedPointer)
    }
}
