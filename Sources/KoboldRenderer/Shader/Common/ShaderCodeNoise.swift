class ShaderCodeNoise {
    public static func getShaderCode(
        variableMap: [String: String]
    ) -> String {
        return variableMap.reduce(shaderCode) { (acc, next) in
            acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
        }
    }

    private static let shaderCode =
"""
float map3dNoiseToRange(float noise, float noiseMin, float noiseMax) {
    float oMax = 1;
    float oMin = -oMax;
    float ratio = (noise - oMin)/(abs(oMin) + abs(oMax));
    float nPos = ratio * (abs(noiseMin) + abs(noiseMax));
    return clamp(noiseMin + nPos, 0.f, 1.f);
}
"""
}
