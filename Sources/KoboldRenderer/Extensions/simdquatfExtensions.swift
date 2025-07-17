import simd

extension simd_quatf {
    static var identity: Self {
        Self(real: 1, imag: .zero)
    }
    
    static func lerp(_ start: Self, _ end: Self, t: Float) -> Self {
        return start * (1 - t) + end * t
    }
    
    static func nlerp(_ start: Self, _ end: Self, t: Float) -> Self {
        return simd_normalize(start + (end - start) * t)
    }
}

