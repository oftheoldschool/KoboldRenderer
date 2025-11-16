struct LightingData {
    let globalLight: KRLight
    let lights: [KRLight]
    let occluders: [KROccluder]
    let cascadedShadowMap: CascadedShadowMap
    let enableLighting: Bool
    let enableShadows: Bool

    init(
        globalLight: KRLight,
        maxLights: Int,
        maxOccluders: Int,
        lights: [KRLight],
        occluders: [KROccluder],
        cascadedShadowMap: CascadedShadowMap,
        enableLighting: Bool,
        enableShadows: Bool
    ) {
        let cappedLights: [KRLight]
        if lights.count <= maxLights {
            cappedLights = lights
        } else {
            print("Number of lights exceeded limit: \(maxLights). \(lights.count - maxLights) will not be included in rendering")
            cappedLights = lights.dropLast(lights.count - maxLights)
        }

        let cappedOccluders: [KROccluder]
        if occluders.count <= maxOccluders {
            cappedOccluders = occluders
        } else {
            print("Number of occluders exceeded limit: \(maxOccluders). \(occluders.count - maxOccluders) will not be included in rendering")
            cappedOccluders = occluders.dropLast(occluders.count - maxOccluders)
        }

        self.globalLight = globalLight
        self.lights = cappedLights
        self.occluders = cappedOccluders
        self.cascadedShadowMap = cascadedShadowMap
        self.enableLighting = enableLighting
        self.enableShadows = enableShadows
    }

    func toLightUniforms() -> [LightUniforms] {
        return lights.map { light in
            let (type, float3Data, attenuation, range, radius): (LightUniformsType, SIMD3<Float>, SIMD3<Float>, Float, Float) = switch light.type {
            case .directional(let directional): (.directional, directional.direction, .zero, .zero, .zero)
            case .point(let point): (.point, point.position, point.attenuation, point.range, point.radius)
            }
            return LightUniforms(
                type: type,
                float3Data: float3Data,
                color: light.color,
                intensity: light.intensity,
                attenuation: attenuation,
                range: range,
                radius: radius
            )
        }
    }
}
