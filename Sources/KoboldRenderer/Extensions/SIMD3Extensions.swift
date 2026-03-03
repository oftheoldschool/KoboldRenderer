import simd

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
