import Foundation
import Swift

extension Sequence {
    func toByteArray() -> [UInt8] {
        return self.flatMap { f in
            withUnsafeBytes(of: f, Array.init)
        }
    }
}

extension Array<SIMD3<Float>> {
    func toByteArray() -> [UInt8] {
        return self.flatMap { [$0.x, $0.y, $0.z] }.toByteArray()
    }
    
    func toPaddedByteArray() -> [UInt8] {
        return self.map { [$0.x, $0.y, $0.z, 0] }.toByteArray()
    }
}
