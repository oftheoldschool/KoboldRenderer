import simd

extension SIMD2 {
    func toArray() -> [Scalar] {
        return [x, y]
    }
}
