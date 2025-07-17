import simd

extension SIMD3 {
    func clone(x: Scalar? = nil, y: Scalar? = nil, z: Scalar? = nil) -> Self {
        return Self(x ?? self.x, y ?? self.y, z ?? self.z)
    }

    func toArray() -> [Scalar] {
        return [x, y, z]
    }
}


extension SIMD3 where Scalar == Float {
    static func lerp(_ start: Self, _ end: Self, t: Scalar) -> Self {
        return Self(
            start.x + (end.x - start.x) * t,
            start.y + (end.y - start.y) * t,
            start.z + (end.z - start.z) * t)
    }

    static func slerp(_ s: Self, _ e: Self, t: Scalar) -> Self {
        if t < 0.01 {
            return lerp(s, e, t: t)
        }

        let from = normalize(s)
        let to = normalize(e)

        let theta = angle(from, to)
        let sinTheta = sinf(theta)

        let a = sinf((1 - t) * theta) / sinTheta
        let b = sin(t * theta) / sinTheta

        return from * a + to * b
    }

    static func nlerp(_ s: Self, _ e: Self, t: Scalar) -> Self {
        let linear = Self(
            s.x + (e.x - s.x) * t,
            s.y + (e.y - s.y) * t,
            s.z + (e.z - s.z) * t)
        return normalize(linear)
    }

    static func angle(_ from: Self, _ to: Self, _ epsilon: Float = 1e-6) -> Scalar {
        let squareMagnitudeFrom = length_squared(from)
        let squareMagnitudeTo = length_squared(to)
        if squareMagnitudeFrom < epsilon || squareMagnitudeTo < epsilon {
            return 0
        }
        let dot = dot(from, to)
        let len = sqrtf(squareMagnitudeFrom) * sqrtf(squareMagnitudeTo)
        return acosf(dot / len)
    }
}

extension SIMD3 where Scalar: SignedNumeric {
    static var xPositive: Self {
        Self(x: 1, y: 0, z: 0)
    }

    static var yPositive: Self {
        Self(x: 0, y: 1, z: 0)
    }

    static var zPositive: Self {
        Self(x: 0, y: 0, z: 1)
    }

    static var xNegative: Self {
        Self(x: -1, y: 0, z: 0)
    }

    static var yNegative: Self {
        Self(x: 0, y: -1, z: 0)
    }

    static var zNegative: Self {
        Self(x: 0, y: 0, z: -1)
    }

    func toPos4() -> SIMD4<Scalar> {
        return SIMD4<Scalar>(self, 1)
    }

    func toDir4() -> SIMD4<Scalar> {
        return SIMD4<Scalar>(self, 0)
    }
}

extension SIMD3 where Scalar: FloatingPoint {
    static var greatest: Self {
        Self(repeating: Scalar.greatestFiniteMagnitude)
    }

    static var least: Self {
        Self(repeating: -Scalar.greatestFiniteMagnitude)
    }
}
