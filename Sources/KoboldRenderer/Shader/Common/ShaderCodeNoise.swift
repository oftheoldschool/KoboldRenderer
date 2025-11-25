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
float map3dNoiseToRange(
    float noise, 
    float noiseMin, 
    float noiseMax,
    bool useSimplexRange
) {
    float oMax = useSimplexRange ? 0.8660254 : 1.0;
    float oMin = -oMax;
    float ratio = (noise - oMin) / (oMax - oMin);
    float result = noiseMin + ratio * (noiseMax - noiseMin);
    return result;
}

float map3dNoiseToRange(
    float noise, 
    float noiseMin, 
    float noiseMax
) {
    return map3dNoiseToRange(noise, noiseMin, noiseMax, true);
}
"""
}

