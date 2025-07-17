class ShaderCodeLighting {
    public static func getShaderCode(
        variableMap: [String: String]
    ) -> String {
        return variableMap.reduce(shaderCode) { (acc, next) in
            acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
        }
    }

    private static let shaderCode =
"""
ShadowCalculationData getShadowCalculationData(
    float3 worldSpacePosition,
    float clipSpacePosZ,
    constant float4x4 * uniformsLightSpaceVolumes
) {
    ShadowCalculationData shadowCalculationData {
        .clipSpacePosZ = clipSpacePosZ,
    };

    REPEAT(
        ${CASCADED_SHADOW_NUM_CASCADES},
        CALCULATE_LIGHTSPACE_POS, 
        float4(worldSpacePosition, 1), 
        uniformsLightSpaceVolumes,
        shadowCalculationData.lightSpacePos_)

    return shadowCalculationData;
}

// Rim lighting modes
enum class RimLightingMode {
    artistic,           // Pure artistic rim using material color only
    lightInfluenced,    // Rim influenced by all lights equally
    directional        // Rim influenced by lights with directional consideration
};

// Helper function to resolve light color
float3 resolveLightColor(
    constant SharedUniforms & uniformsShared, 
    constant LightUniforms & light
) {
    return (uniformsShared.globalLightingColor.x == 0 
            && uniformsShared.globalLightingColor.y == 0 
            && uniformsShared.globalLightingColor.z == 0)
        ? light.color
        : uniformsShared.globalLightingColor;
}

// Calculate light direction and attenuation
struct LightContribution {
    float3 direction;
    float attenuation;
};

// Calculate diffuse and specular lighting
struct SurfaceLighting {
    float3 diffuse;
    float3 specular;
};

LightContribution calculateLightContribution(
    constant LightUniforms & light, 
    float3 worldPosition
) {
    LightContribution result;
    result.attenuation = 1.0;
    
    if (light.type == LightUniformsType::directional) {
        result.direction = normalize(light.float3Data);
    } else if (light.type == LightUniformsType::point) {
        float3 lightPos = light.float3Data;
        float3 toFragment = worldPosition - lightPos;
        float distance = length(toFragment);
        
        if (distance > light.range) {
            result.attenuation = 0.0;
        } else {
            // Custom attenuation: constant + linear + quadratic
            result.attenuation = 1.0 / (light.attenuation.x + 
                                      light.attenuation.y * distance + 
                                      light.attenuation.z * distance * distance);
            
            // Smooth falloff at range boundaries
            float rangeAttenuation = 1.0 - smoothstep(0.75 * light.range, light.range, distance);
            result.attenuation *= rangeAttenuation;
        }
        
        result.direction = normalize(toFragment);
    }
    
    result.attenuation *= light.intensity;
    return result;
}

// Calculate shadow factor for multi-light setup
float calculateShadowFactor(
    uint8_t lightIndex, 
    float baseShadowFactor, 
    float3 normal, 
    float3 lightDirection, 
    float attenuation
) {
    if (lightIndex == 0) {
        return baseShadowFactor; // Primary light uses calculated shadow
    }
    
    // Additional lights reduce shadow based on contribution
    float lightContribution = max(0.0, dot(normal, -lightDirection)) * attenuation;
    float shadowReduction = lightContribution * 0.8; 
    return baseShadowFactor + (1.0 - baseShadowFactor) * shadowReduction;
}

// Calculate ambient lighting contribution
float3 calculateAmbient(
    constant LightUniforms & light, 
    float3 lightColor, 
    float attenuation
) {
    if (light.type == LightUniformsType::point) {
        return lightColor * light.ambientStrength * attenuation;
    } else {
        return lightColor * light.ambientStrength; // Directional = global ambient
    }
}

SurfaceLighting calculateSurfaceLighting(
    constant LightUniforms & light, 
    float3 lightColor,
    float3 normal, 
    float3 lightDirection, 
    float3 worldPosition,
    constant SharedUniforms & uniformsShared, 
    float attenuation, 
    float shadowFactor
) {
    SurfaceLighting result = {float3(0), float3(0)};
    
    float diffuseFactor = max(0.0, dot(normal, -lightDirection));
    if (diffuseFactor > 0) {
        // Diffuse
        result.diffuse = lightColor * diffuseFactor * attenuation * shadowFactor;
        
        // Specular
        float3 viewDirection = normalize(uniformsShared.cameraPosition - worldPosition);
        float3 reflectDirection = normalize(reflect(lightDirection, normal));
        float specularFactor = max(0.0, dot(viewDirection, reflectDirection));
        float specular = pow(specularFactor, light.specularPower);
        result.specular = light.specularStrength * specular * lightColor * attenuation * shadowFactor;
    }
    
    return result;
}

// Calculate rim lighting effect
float3 calculateRimLighting(
    constant SharedUniforms & uniformsShared,
    constant LightUniforms * uniformsLights,
    float3 worldPosition, 
    float3 normal,
    float rimIntensity, 
    float rimPower, 
    float3 rimColor,
    RimLightingMode rimMode
) {
    if (rimIntensity <= 0.0) return float3(0);
    
    float3 viewDirection = normalize(uniformsShared.cameraPosition - worldPosition);
    float rim = 1.0 - max(0.0, dot(normal, viewDirection));
    rim = pow(rim, rimPower);
    
    if (rimMode == RimLightingMode::lightInfluenced || rimMode == RimLightingMode::directional) {
        // Accumulate light contributions for rim
        float3 totalRimLight = float3(0);
        float3 viewDirection = normalize(uniformsShared.cameraPosition - worldPosition);
        
        for (uint8_t i = 0; i < uniformsShared.lightCount; ++i) {
            constant LightUniforms & light = uniformsLights[i];
            float3 lightColor = resolveLightColor(
                uniformsShared, 
                light
            );
            
            LightContribution lightContrib = calculateLightContribution(
                light, 
                worldPosition
            );
            
            float rimContribution = lightContrib.attenuation;
            
            // Apply directional rim factor if enabled
            if (rimMode == RimLightingMode::directional) {
                // Calculate how much the light direction aligns with the view-to-surface direction
                // This creates rim lighting that appears on the side facing away from the light
                float3 lightToSurface = -lightContrib.direction;
                float lightViewAlignment = max(0.0, dot(lightToSurface, viewDirection));
                
                // Use a power function to control the falloff
                rimContribution *= pow(lightViewAlignment, 2.0);
            }
            
            totalRimLight += lightColor * rimContribution;
        }
        return rimColor * totalRimLight * rimIntensity * rim;
    } else {
        // Pure artistic rim
        return rimColor * rimIntensity * 0.5 * rim;
    }
}

// Main lighting calculation function
float4 calculateLighting(
    constant SharedUniforms & uniformsShared,
    constant LightUniforms * uniformsLights,
    float3 worldPosition,
    float3 normal,
    float3 baseColor, 
    float baseAlpha, 
    float baseShadowFactor,
    bool enableLighting,
    float rimIntensity = 0.6,
    float rimPower = 2.0,
    float3 rimColor = float3(1.0, 1.0, 1.0),
    RimLightingMode rimMode = RimLightingMode::lightInfluenced
) {
    if (!enableLighting) {
        return float4(baseColor * baseShadowFactor, baseAlpha);
    }
    
    float3 N = normal;
    float3 totalAmbient = float3(0);
    float3 totalDiffuse = float3(0);
    float3 totalSpecular = float3(0);

    // Process each light
    for (uint8_t i = 0; i < uniformsShared.lightCount; ++i) {
        constant LightUniforms & light = uniformsLights[i];
        float3 lightColor = resolveLightColor(
            uniformsShared, 
            light
        );
        
        LightContribution lightContrib = calculateLightContribution(
            light, 
            worldPosition
        );
        if (lightContrib.attenuation <= 0.0) continue; // Skip lights with no contribution
        
        float shadowFactor = calculateShadowFactor(
            i, 
            baseShadowFactor, 
            N, 
            lightContrib.direction, 
            lightContrib.attenuation
        );
        
        // Accumulate lighting terms
        totalAmbient += calculateAmbient(
            light, 
            lightColor, 
            lightContrib.attenuation
        );
        
        SurfaceLighting surface = calculateSurfaceLighting(
            light, 
            lightColor, 
            N, 
            lightContrib.direction, 
            worldPosition,
            uniformsShared, 
            lightContrib.attenuation, 
            shadowFactor
        );
        totalDiffuse += surface.diffuse;
        totalSpecular += surface.specular;
    }
    
    // Add rim lighting
    float3 rimTerm = calculateRimLighting(
        uniformsShared, 
        uniformsLights, 
        worldPosition, 
        N,
        rimIntensity, 
        rimPower, 
        rimColor, 
        rimMode
    );
    
    // Combine all lighting terms
    float3 finalColor = baseColor * (totalAmbient + totalDiffuse) + totalSpecular + rimTerm;
    return float4(finalColor, baseAlpha);
}

float4 calculateBloom(
    float4 inputColor,
    float3 bloomThreshold,
    float3 bloomMultiplier
) {
    float brightness = max(max(inputColor.r, inputColor.g), inputColor.b);
    float contribution = max(0.0, brightness - bloomThreshold.x);
    contribution = smoothstep(0.0, 0.5, contribution);
    float4 outputBrightness = inputColor * contribution * float4(bloomMultiplier, 1.0);
    outputBrightness.a = 1.0;
    return outputBrightness;
}
"""
}
