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

float3 resolveLightColor(
    constant LightingUniforms & uniformsLighting, 
    constant LightUniforms & light
) {
    return (uniformsLighting.globalLightingColor.x == 0 
            && uniformsLighting.globalLightingColor.y == 0 
            && uniformsLighting.globalLightingColor.z == 0)
        ? light.color
        : uniformsLighting.globalLightingColor;
}

struct LightContribution {
    float3 direction;
    float attenuation;
};

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
        
        // Check for infinite range (use negative or zero range to indicate infinite)
        if (light.range <= 0.0) {
            // Infinite range - no distance falloff, only custom attenuation
            result.attenuation = 1.0;
        } else if (distance > light.range) {
            result.attenuation = 0.0;
        } else {
            // Finite range with custom attenuation
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

float3 calculateAmbient(
    constant LightUniforms & light, 
    float3 lightColor, 
    float attenuation,
    float ambientFactor
) {
    if (light.type == LightUniformsType::point) {
        return lightColor * ambientFactor * attenuation;
    } else {
        return lightColor * ambientFactor; // Directional = global ambient
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
    float shadowFactor,
    float shininess,
    float specularIntensity
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
        float specular = pow(specularFactor, max(shininess, 1.f));
        result.specular = specularIntensity * specular * lightColor * attenuation * shadowFactor;
    }
    
    return result;
}

float3 calculateRimLighting(
    constant SharedUniforms & uniformsShared,
    constant LightingUniforms & uniformsLighting,
    constant LightUniforms * uniformsLights,
    float3 worldPosition, 
    float3 normal,
    float rimIntensity, 
    float rimPower, 
    float3 rimColor,
    RimLightingMode rimMode
) {
    if (rimIntensity <= 0.0 || rimMode == RimLightingMode::none) {
        return float3(0);
    }
    
    float3 viewDirection = normalize(uniformsShared.cameraPosition - worldPosition);
    float rim = 1.0 - max(0.0, dot(normal, viewDirection));
    rim = pow(rim, rimPower);
    
    if (rimMode == RimLightingMode::lightInfluenced || rimMode == RimLightingMode::directional) {
        // Accumulate light contributions for rim
        float3 totalRimLight = float3(0);
        float3 viewDirection = normalize(uniformsShared.cameraPosition - worldPosition);
        
        for (uint8_t i = 0; i < uniformsLighting.lightCount; ++i) {
            constant LightUniforms & light = uniformsLights[i];
            float3 lightColor = resolveLightColor(
                uniformsLighting, 
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

float4 calculateLighting(
    constant SharedUniforms & uniformsShared,
    constant LightingUniforms & uniformsLighting,
    constant LightUniforms * uniformsLights,
    float3 worldPosition,
    float3 normal,
    MaterialParameters materialParameters, 
    float baseShadowFactor,
    bool enableLighting
) {
    if (!enableLighting) {
        return float4(materialParameters.color.rgb * baseShadowFactor, materialParameters.color.a);
    }
    
    float3 N = normal;
    float3 totalAmbient = float3(0);
    float3 totalDiffuse = float3(0);
    float3 totalSpecular = float3(0);

    // Process each light
    for (uint8_t i = 0; i < uniformsLighting.lightCount; ++i) {
        constant LightUniforms & light = uniformsLights[i];
        float3 lightColor = resolveLightColor(
            uniformsLighting, 
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
            lightContrib.attenuation,
            materialParameters.ambientFactor
        );
        
        SurfaceLighting surface = calculateSurfaceLighting(
            light, 
            lightColor, 
            N, 
            lightContrib.direction, 
            worldPosition,
            uniformsShared, 
            lightContrib.attenuation, 
            shadowFactor,
            materialParameters.shininess,
            materialParameters.specularIntensity
        );
        totalDiffuse += surface.diffuse;
        totalSpecular += surface.specular;
    }
    
    // Add rim lighting
    float3 rimTerm = calculateRimLighting(
        uniformsShared,
        uniformsLighting,
        uniformsLights,
        worldPosition,
        N,
        materialParameters.rimIntensity, 
        materialParameters.rimPower, 
        materialParameters.rimColor, 
        materialParameters.rimLightingMode
    );
    
    // Combine all lighting terms
    float3 finalColor = materialParameters.color.rgb * (totalAmbient + totalDiffuse) + totalSpecular + rimTerm;
    return float4(finalColor, materialParameters.color.a);
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
