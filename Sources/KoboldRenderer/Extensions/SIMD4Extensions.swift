import simd

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        return SIMD3<Scalar>(x, y, z)
    }

    func clone(x: Scalar? = nil, y: Scalar? = nil, z: Scalar? = nil, w: Scalar? = nil) -> Self {
        return Self(x ?? self.x, y ?? self.y, z ?? self.z, w ?? self.w)
    }
}

extension SIMD4 where Scalar: SignedNumeric {
    static var xPositive: Self {
        Self(x: 1, y: 0, z: 0, w: 0)
    }

    static var yPositive: Self {
        Self(x: 0, y: 1, z: 0, w: 0)
    }

    static var zPositive: Self {
        Self(x: 0, y: 0, z: 1, w: 0)
    }

    static var wPositive: Self {
        Self(x: 0, y: 0, z: 0, w: 1)
    }

    static var xNegative: Self {
        Self(x: -1, y: 0, z: 0, w: 0)
    }

    static var yNegative: Self {
        Self(x: 0, y: -1, z: 0, w: 0)
    }

    static var zNegative: Self {
        Self(x: 0, y: 0, z: -1, w: 0)
    }

    static var wNegative: Self {
        Self(x: 0, y: 0, z: 0, w: -1)
    }
}
