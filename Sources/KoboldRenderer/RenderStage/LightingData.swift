struct LightingData {
    let globalLight: KRLight
    let lights: [KRLight]
    let cascadedShadowMap: CascadedShadowMap
    let bloomThreshold: SIMD3<Float>
    let bloomMultiplier: SIMD3<Float>
    let enableLighting: Bool
    let enableShadows: Bool

    init(
        globalLight: KRLight,
        maxLights: Int,
        lights: [KRLight],
        cascadedShadowMap: CascadedShadowMap,
        bloomThreshold: SIMD3<Float>,
        bloomMultiplier: SIMD3<Float>,
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
        self.globalLight = globalLight
        self.lights = cappedLights
        self.cascadedShadowMap = cascadedShadowMap
        self.bloomThreshold = bloomThreshold
        self.bloomMultiplier = bloomMultiplier
        self.enableLighting = enableLighting
        self.enableShadows = enableShadows
    }

    func toLightUniforms() -> [LightUniforms] {
        return lights.map { light in
            let (type, float3Data, attenuation, range): (LightUniformsType, SIMD3<Float>, SIMD3<Float>, Float) = switch light.type {
            case .directional(let directional): (.directional, directional.direction, .zero, .zero)
            case .point(let point): (.point, point.position, point.attenuation, point.range)
            }
            return LightUniforms(
                type: type,
                float3Data: float3Data,
                color: light.color,
                intensity: light.intensity,
                attenuation: attenuation,
                range: range
            )
        }
    }
}
