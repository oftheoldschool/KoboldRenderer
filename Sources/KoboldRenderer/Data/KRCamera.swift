import simd

public class KRCamera {
    public var volume: KRCameraVolume
    public var position: SIMD3<Float>
    public var orientation: simd_quatf
    public var up: SIMD3<Float> {
        get { orientation.act(.yPositive) }
    }
    public var forward: SIMD3<Float> {
        get { orientation.act(.zPositive) }
    }

    public init(
        volume: KRCameraVolume,
        position: SIMD3<Float>,
        direction: SIMD3<Float>,
        up: SIMD3<Float>? = nil,
        leftHanded: Bool = false
    ) {
        self.volume = volume
        self.position = position
        if let u = up {
            let right = leftHanded ? cross(u, direction) : cross(direction, u)
            let f = simd_normalize(direction)
            let u = simd_normalize(u)
            let r = simd_normalize(right)

            let actualHandedness = dot(cross(r, u), f)
            print("target handedness: \(leftHanded ? "left" : "right")")
            print("actual handedness: \(actualHandedness == 0 ? "either" : (actualHandedness > 0 ? "right" : "left"))")

            let rotationMatrix = float3x3(columns: (r, u, f))
            self.orientation = simd_quatf(rotationMatrix)
        } else {
            self.orientation = simd_quatf(from:.zPositive, to: direction)
        }
    }

    public init(
        volume: KRCameraVolume,
        position: SIMD3<Float>,
        orientation: simd_quatf = simd_quatf(real: 1, imag: .zero)
    ) {
        self.volume = volume
        self.position = position
        self.orientation = orientation
    }

    public func viewMatrix() -> float4x4 {
        return float4x4.lookAt(
            from: position,
            to: position + forward,
            up: up)
    }

    public func projectionMatrix() -> float4x4 {
        return switch volume {
        case .perspective(let volume):
            volume.toMatrix()
        case .orthographic(let volume):
            volume.toMatrix()
        }
    }
}
