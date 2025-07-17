import Foundation
import simd

extension KRVolumePerspective {
    // input must add up to 1: [0.25, 0.5, 0.25]
    func calculateFrustumLimitsInCameraSpace(
        frustumRatios: [Float]
    ) -> [Float] {
        var limit: Float = near
        var frustumLimits: [Float] = [limit]
        let range = far - near
        for ratio in frustumRatios {
            limit += (ratio * range)
            frustumLimits.append(limit)
        }
        return frustumLimits
    }

    func calculateFrustumCornersInCameraSpace(
        frustumRatios: [Float]
    ) -> [[SIMD4<Float>]] {
            let cascadeLimits = calculateFrustumLimitsInCameraSpace(frustumRatios: frustumRatios)

            let aspectRatio = aspectRatio
            var tanHalfHFOV = tanf(fov * 0.5)
            var tanHalfVFOV = tanf(fov * 0.5) / aspectRatio

            if aspectRatio < 1 {
                tanHalfHFOV = tanf(fov * 0.5) * aspectRatio
                tanHalfVFOV = tanf(fov * 0.5)
            }

            return (0..<frustumRatios.count).map { i in
                let xn = cascadeLimits[i] * tanHalfHFOV
                let xf = cascadeLimits[i + 1] * tanHalfHFOV
                let yn = cascadeLimits[i] * tanHalfVFOV
                let yf = cascadeLimits[i + 1] * tanHalfVFOV

                return [
                    SIMD4<Float>(xn, yn, -cascadeLimits[i], 1),
                    SIMD4<Float>(-xn, yn, -cascadeLimits[i], 1),
                    SIMD4<Float>(xn, -yn, -cascadeLimits[i], 1),
                    SIMD4<Float>(-xn, -yn, -cascadeLimits[i], 1),

                    SIMD4<Float>(xf, yf, -cascadeLimits[i + 1], 1),
                    SIMD4<Float>(-xf, yf, -cascadeLimits[i + 1], 1),
                    SIMD4<Float>(xf, -yf, -cascadeLimits[i + 1], 1),
                    SIMD4<Float>(-xf, -yf, -cascadeLimits[i + 1], 1),
                ]
            }
    }

    func calculateOrthographicVolumesInLightSpace(
        frustumRatios: [Float],
        currentViewMatrix: float4x4,
        targetViewMatrix: float4x4
    ) -> [KRVolumeOrthographic] {
        let inverseCurrentViewMatrix = currentViewMatrix.inverse

        return calculateFrustumCornersInCameraSpace(
            frustumRatios: frustumRatios
        ).map { frustumCorners in
            let initialValue = (SIMD3<Float>.greatest, SIMD3<Float>.least)
            let (min, max) = frustumCorners
                .map { targetViewMatrix * inverseCurrentViewMatrix * $0 }
                .reduce(initialValue) { (carriedValue, nextValue) in

                    var (min, max) = carriedValue

                    min.x = fmin(min.x, nextValue.x)
                    max.x = fmax(max.x, nextValue.x)
                    min.y = fmin(min.y, nextValue.y)
                    max.y = fmax(max.y, nextValue.y)
                    min.z = fmin(min.z, nextValue.z)
                    max.z = fmax(max.z, nextValue.z)

                    return (min, max)
                }

            // allows "undershoot" of z range. I found that when the camera was looking from the light direction, the AABBs were
            // closely aligned and shadows of objects entirely in AABBs closer the camera were not cast into those further away.
            // This led to part of the shadow being cast in the nearer AABB, and nothing in the further AABB. The overshoot
            // extends the z distance of the bounding box towards the light direction to allow for overlap when the camera
            // and light direction are aligned. An optimisation for shadow quality could be to do this only when the camera and
            // light direction are aligned.
            let zRange = min.z - max.z
            let zUndershoot = abs(zRange * 0.25) // question: is this related to the cascade boundary intentionally?

            // in light space the z axis is flipped, requiring the min and max z values to be flipped when returning the projection
            return KRVolumeOrthographic(
                left: min.x,               right:  max.x,
                top:  max.y,               bottom: min.y,
                near: max.z + zUndershoot, far:    min.z)
        }
    }
}
