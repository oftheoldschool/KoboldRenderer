class ShaderCodeCommon {
    static let shaderCode =
"""
#define REP1(FN, ...) FN(0, ##__VA_ARGS__)
#define REP2(FN, ...) REP1(FN, ##__VA_ARGS__) FN(1, ##__VA_ARGS__)
#define REP3(FN, ...) REP2(FN, ##__VA_ARGS__) FN(2, ##__VA_ARGS__)
#define REP4(FN, ...) REP3(FN, ##__VA_ARGS__) FN(3, ##__VA_ARGS__)
#define REP5(FN, ...) REP4(FN, ##__VA_ARGS__) FN(4, ##__VA_ARGS__)
#define REP6(FN, ...) REP5(FN, ##__VA_ARGS__) FN(5, ##__VA_ARGS__)
#define REP7(FN, ...) REP6(FN, ##__VA_ARGS__) FN(6, ##__VA_ARGS__)
#define REP8(FN, ...) REP7(FN, ##__VA_ARGS__) FN(7, ##__VA_ARGS__)
#define REP9(FN, ...) REP8(FN, ##__VA_ARGS__) FN(8, ##__VA_ARGS__)
#define REP10(FN, ...) REP9(FN, ##__VA_ARGS__) FN(9, ##__VA_ARGS__)
#define REP11(FN, ...) REP10(FN, ##__VA_ARGS__) FN(10, ##__VA_ARGS__)
#define REP12(FN, ...) REP11(FN, ##__VA_ARGS__) FN(11, ##__VA_ARGS__)
#define REP13(FN, ...) REP12(FN, ##__VA_ARGS__) FN(12, ##__VA_ARGS__)
#define REP14(FN, ...) REP13(FN, ##__VA_ARGS__) FN(13, ##__VA_ARGS__)
#define REP15(FN, ...) REP14(FN, ##__VA_ARGS__) FN(14, ##__VA_ARGS__)
#define REP16(FN, ...) REP15(FN, ##__VA_ARGS__) FN(15, ##__VA_ARGS__)
#define REPEAT(N, ...) REP ## N(__VA_ARGS__)

#define DECLARE_VAR( \
    INDEX, \
    VAR_TYPE, \
    VAR_PREFIX \
) \
VAR_TYPE VAR_PREFIX ## INDEX;

enum class FlatShadingMode: int8_t {
    disabled = 0,
    enabled = 1,
    global = 2,
};

enum class MaterialUniformsType: int8_t {
    none = 0,
    debugPosition = 1,
    debugNormal = 2,
    debugColor = 3,
    debugCascade = 4,
    procedural = 5,
    color = 6,
    texture = 7,
};

enum class LightUniformsType: int8_t {
    directional = 0,
    point = 1,
};

enum class RimLightingMode: int8_t {
    none = 0,
    artistic = 1,          // Pure artistic rim using material color only
    lightInfluenced = 2,   // Rim influenced by all lights equally
    directional = 3        // Rim influenced by lights with directional consideration
};

struct MaterialUniforms {
    float4 color;
    float ambientFactor;
    float shininess;
    float specularIntensity;
    float rimIntensity;
    float3 rimColor;
    float rimPower;
    MaterialUniformsType materialType;
    FlatShadingMode flatShadingMode;
    RimLightingMode rimLightingMode;
    bool applyLight;
    bool receiveShadow;
};

struct MaterialParameters {
    float4 color;
    float ambientFactor;
    float shininess;
    float specularIntensity;
    float rimIntensity;
    float3 rimColor;
    float rimPower;
    RimLightingMode rimLightingMode;
};

inline float3x3 upperLeft(float4x4 in) {
    return float3x3(
        in[0].xyz,
        in[1].xyz,
        in[2].xyz);
}

"""

    static func getShaderCode(
        includeHeader: Bool = false,
        variableMap: [String: String] = [:],
        vertexLayouts: [VertexLayout],
        structLayouts: [StructLayout]
    ) -> String {
        let header =
"""
#include <metal_stdlib>
using namespace metal;
"""
        let baseFunction =
"""
\(includeHeader ? header : "")

\(Self.shaderCode)

\(structLayouts.map { $0.toMetalShaderStruct() }.joined(separator: "\n\n"))

\(vertexLayouts.map { $0.toMetalShaderStruct() }.joined(separator: "\n\n"))

"""
        return variableMap.reduce(baseFunction) { (acc, next) in
            acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
        }
    }
}
