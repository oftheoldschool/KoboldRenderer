class ShaderCodeColor {
    public static func getShaderCode(
        variableMap: [String: String]
    ) -> String {
        return variableMap.reduce(shaderCode) { (acc, next) in
            acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
        }
    }

    private static let shaderCode =
"""

MaterialParameters resolveMaterial(
    constant MaterialUniforms & material,
    constant MaterialUniforms & globalMaterial,
    float3 worldPosition,
    float3 worldNormal,
    int cascadeIndex,
    float4 inputColor
) {
    float4 materialParameters = inputColor;

    constant MaterialUniforms & finalMaterial = (globalMaterial.materialType != MaterialUniformsType::none)
        ? globalMaterial
        : material;

    if (finalMaterial.materialType == MaterialUniformsType::debugPosition) {
        materialParameters = float4((worldPosition + 1) / 2, 1);
    } else if (finalMaterial.materialType == MaterialUniformsType::debugNormal) {
        materialParameters = float4((worldNormal + 1) / 2, 1);
    } else if (finalMaterial.materialType == MaterialUniformsType::debugColor) {
        materialParameters = finalMaterial.color;
    } else if (finalMaterial.materialType == MaterialUniformsType::debugCascade) {
        if (cascadeIndex == 0) {
            materialParameters = float4(1, 0, 0, 1);
        } else if (cascadeIndex == 1) {
            materialParameters = float4(0, 1, 0, 1);
        } else if (cascadeIndex == 2) {
            materialParameters = float4(0, 0, 1, 1);
        }
    }
    return {
        .color = materialParameters,
        .ambientFactor = finalMaterial.ambientFactor,
        .shininess = finalMaterial.shininess,
        .specularIntensity = finalMaterial.specularIntensity,
    };
}

float3 getResolvedNormal(
    constant SharedUniforms & uniformsShared,
    constant MaterialUniforms & material,
    float3 worldPosition,
    float3 worldNormal
) {
    if (
        uniformsShared.enableFlatShading 
        && (material.flatShadingMode == FlatShadingMode::global
            || material.flatShadingMode == FlatShadingMode::enabled)
    ) {
        float3 dpdx = dfdx(worldPosition);
        float3 dpdy = dfdy(worldPosition);
        return -normalize(cross(dpdx, dpdy));
    } else {
        return normalize(worldNormal);
    }
}
"""
}
