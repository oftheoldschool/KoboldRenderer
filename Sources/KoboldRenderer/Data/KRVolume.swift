import simd

public enum KRCameraVolume {
    case perspective(KRVolumePerspective)
    case orthographic(KRVolumeOrthographic)
}

public class KRVolumePerspective {
    public var near: Float
    public var far: Float
    public var aspectRatio: Float
    public var fov: Float
    
    public init(
        near: Float,
        far: Float,
        aspectRatio: Float,
        fov: Float
    ) {
        self.near = near
        self.far = far
        self.aspectRatio = aspectRatio
        self.fov = fov
    }
    
    public func toMatrix() -> float4x4 {
        return float4x4.perspectiveProjection(
            fov: fov,
            aspectRatio: aspectRatio,
            near: near,
            far: far)
    }
}

public class KRVolumeOrthographic {
    let left: Float
    let right: Float
    let top: Float
    let bottom: Float
    let near: Float
    let far: Float
    
    init(
        left: Float, right: Float,
        top: Float, bottom: Float,
        near: Float, far: Float
    ) {
        self.left = left
        self.right = right
        self.top = top
        self.bottom = bottom
        self.near = near
        self.far = far
    }
    
    public func toMatrix() -> float4x4 {
        return float4x4.orthographicProjection(
            left: left, right: right,
            bottom: bottom, top: top,
            near: near, far: far)
    }
}
