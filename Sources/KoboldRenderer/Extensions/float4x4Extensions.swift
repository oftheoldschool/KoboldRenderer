import simd

extension float3x3 {
    func toFloat4x4() -> float4x4 {
        return float4x4(
            SIMD4<Float>(self[0], 0),
            SIMD4<Float>(self[1], 0),
            SIMD4<Float>(self[2], 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
}

extension float4x4 {
    public var upperLeft: float3x3 {
        return float3x3(self[0].xyz, self[1].xyz, self[2].xyz)
    }
    
    public var diagonal: SIMD4<Float> {
        return SIMD4<Float>(
            x: self[0][0],
            y: self[1][1],
            z: self[2][2],
            w: self[3][3])
    }

    public var normalMatrix: float3x3 {
        let upperLeft = float3x3(self[0].xyz, self[1].xyz, self[2].xyz)
        return upperLeft.inverse.transpose
    }
    
    public func toRotationScaleMatrix() -> Self {
        return Self(
            SIMD4<Float>(self[0].xyz, 0),
            SIMD4<Float>(self[1].xyz, 0),
            SIMD4<Float>(self[2].xyz, 0),
            SIMD4<Float>.wPositive)
    }
    
    public static func orthographicProjection(
        left: Float,
        right: Float,
        bottom: Float,
        top: Float,
        near: Float,
        far: Float
    ) -> Self {
        let xx: Float = 2.0 / (right - left)
        let xy: Float = 0
        let xz: Float = 0
        let xw: Float = 0

        let yx: Float = 0
        let yy: Float = 2.0 / (top - bottom)
        let yz: Float = 0
        let yw: Float = 0

        let zx: Float = 0
        let zy: Float = 0
        let zz: Float = -1.0 / (far - near)
        let zw: Float = 0

        let wx: Float = -(right + left) / (right - left)
        let wy: Float = -(top + bottom) / (top - bottom)
        let wz: Float = -near / (far - near)
        let ww: Float = 1

        return Self(
            SIMD4<Float>( xx, xy, xz, xw),
            SIMD4<Float>( yx, yy, yz, yw),
            SIMD4<Float>( zx, zy, zz, zw),
            SIMD4<Float>( wx, wy, wz, ww)
        )
    }

    public static func perspectiveProjection(
        fov: Float,
        aspectRatio: Float,
        near: Float,
        far: Float
    ) -> Self {
        // corresponds to perspectiveRH_Z0=O
        let halfTanFovX = tan(fov * 0.5)
        
        var xScale = 1 / halfTanFovX
        var yScale = 1 / (halfTanFovX / aspectRatio)

        // workaround for the case where height > width
        if aspectRatio < 1 {
            xScale = 1 / (halfTanFovX * aspectRatio)
            yScale = 1 / halfTanFovX
        }
        
        let zRange = far - near
        let zScale = far / (near - far)
        let wzScale =  -(far * near) / zRange
        
        let xx = xScale
        let yy = yScale
        let zz = zScale
        let zw = Float(-1)
        let wz = wzScale
        
        return Self.init(
            SIMD4<Float>(xx,  0,  0,  0),
            SIMD4<Float>( 0, yy,  0,  0),
            SIMD4<Float>( 0,  0, zz, zw),
            SIMD4<Float>( 0,  0, wz,  0))
    }
    
    static func lookAt(
        from: SIMD3<Float>, 
        to: SIMD3<Float>, 
        up: SIMD3<Float>
    ) -> Self {
        // corresponds to lookAtRH (https://github.com/g-truc/glm/blob/fc8f4bb442b9540969f2f3f351c4960d91bca17a/glm/ext/matrix_transform.inl#L153-L173)
        let forward = normalize(to - from)
        let right = normalize(cross(forward, up))
        let up = cross(right, forward)
        return Self.init([
            [right.x, up.x, -forward.x, 0],
            [right.y, up.y, -forward.y, 0],
            [right.z, up.z, -forward.z, 0],
            [-dot(right, from), -dot(up, from), dot(forward, from), 1],
        ])
    }

    init(scaleBy s: Float) {
        self.init(SIMD4<Float>(s, 0, 0, 0),
                  SIMD4<Float>(0, s, 0, 0),
                  SIMD4<Float>(0, 0, s, 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }

    init(scaleBy v: SIMD3<Float>) {
        self.init(SIMD4<Float>(v.x, 0, 0, 0),
                  SIMD4<Float>(0, v.y, 0, 0),
                  SIMD4<Float>(0, 0, v.z, 0),
                  SIMD4<Float>(0, 0, 0, 1))
    }

    init(rotationAbout axis: SIMD3<Float>, by angleRadians: Float) {
        let x = axis.x, y = axis.y, z = axis.z
        let c = cosf(angleRadians)
        let s = sinf(angleRadians)
        let t = 1 - c
        self.init(
            SIMD4<Float>(
                t * x * x + c,
                t * x * y + z * s,
                t * x * z - y * s, 0),
            SIMD4<Float>(
                t * x * y - z * s,
                t * y * y + c,
                t * y * z + x * s,
                0),
            SIMD4<Float>(
                t * x * z + y * s,
                t * y * z - x * s,
                t * z * z + c,
                0),
            SIMD4<Float>(0, 0, 0, 1))
    }

    init(translationBy t: SIMD3<Float>) {
        self.init(SIMD4<Float>(   1,    0,    0, 0),
                  SIMD4<Float>(   0,    1,    0, 0),
                  SIMD4<Float>(   0,    0,    1, 0),
                  SIMD4<Float>(t[0], t[1], t[2], 1))
    }
}
