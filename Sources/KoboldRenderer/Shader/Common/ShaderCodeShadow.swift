class ShaderCodeShadow {
    public static func getShaderCode(
        variableMap: [String: String]
    ) -> String {
        return variableMap.reduce(shaderCode) { (acc, next) in
            acc.replacingOccurrences(of: "${\(next.key)}", with: next.value)
        }
    }

    private static let shaderCode =
"""
float calculateCSMShadowFactor(
    float4 lightSpacePos,
    depth2d_array<float, access::sample> shadowTextures,
    sampler shadowSampler,
    float cascadeIndex,
    constant SharedUniforms & uniformsShared
) {
    float3 projCoords = (lightSpacePos.xyz / lightSpacePos.w);
    float2 uvCoords = (projCoords.xy * 0.5) + 0.5;
    uvCoords.y = 1 - uvCoords.y;

    float shadow = 0.0;

    float bias = uniformsShared.shadowNormalBias;
    bias *= 1.0 + (1.0 - abs(dot(float3(0, 0, 1), normalize(projCoords)))) * uniformsShared.shadowBiasAngleFactor;
    bias *= (1.0 + cascadeIndex * uniformsShared.shadowCascadeFactor);

    float currentDepth = projCoords.z - bias;

    float2 texelSize = 1.0 / float2(${CASCADED_SHADOW_BASE_SIZE});
    int filterSize = 5 + int(cascadeIndex);
    filterSize = min(filterSize, 5);
    int halfFilterSize = (filterSize - 1) / 2;

    float totalWeight = 0.0;

    for(int x = -halfFilterSize; x <= halfFilterSize; ++x) {
        for(int y = -halfFilterSize; y <= halfFilterSize; ++y) {
            float2 offset = float2(x, y) * texelSize;
            float pcfDepth = shadowTextures.sample_compare(shadowSampler, uvCoords + offset, cascadeIndex, currentDepth);
            
            float weight = 1.0 - length(float2(x, y)) / (halfFilterSize * 1.5);
            weight = max(0.1, weight);
            
            shadow += pcfDepth * weight;
            totalWeight += weight;
        }
    }

    shadow /= totalWeight;

    if (any(abs(projCoords.xy) > 0.95)) {
        float edgeFactor = 1.0 - max(abs(projCoords.x), abs(projCoords.y));
        edgeFactor = smoothstep(0.0, 0.05, edgeFactor);
        shadow = mix(1.0, shadow, edgeFactor);
    }

    return shadow;
}

#define CALCULATE_LIGHTSPACE_POS( \
INDEX, \
IN_WORLD_POSITION, \
IN_LIGHT_VOLUMES, \
OUT_LIGHTSPACE_PREFIX \
) \
OUT_LIGHTSPACE_PREFIX ## INDEX = IN_LIGHT_VOLUMES[INDEX] * IN_WORLD_POSITION;

#define CALCULATE_CSM_SHADOW_FACTOR( \
    INDEX, \ 
    IN_LIGHTSPACE_PREFIX, \
    IN_CLIP_SPACE_POS_Z, \
    IN_CASCADE_END_CLIP_SPACE, \
    IN_CASCADED_SHADOW_TEXTURE, \
    IN_CASCADED_SHADOW_SAMPLER, \
    OUT_CASCADE_INDEX, \
    OUT_SHADOW_FACTOR, \
    IN_UNIFORMS_SHARED \
) \
if (OUT_CASCADE_INDEX < 0 && IN_CLIP_SPACE_POS_Z <= IN_CASCADE_END_CLIP_SPACE[INDEX]) { \
    OUT_SHADOW_FACTOR = calculateCSMShadowFactor( \
        IN_LIGHTSPACE_PREFIX ## INDEX, \
        IN_CASCADED_SHADOW_TEXTURE, \
        IN_CASCADED_SHADOW_SAMPLER, \
        INDEX, \
        IN_UNIFORMS_SHARED); \
    OUT_CASCADE_INDEX = INDEX; \
    if (INDEX == (${CASCADED_SHADOW_NUM_CASCADES} - 1)) { \
        OUT_SHADOW_FACTOR = mix( \
            OUT_SHADOW_FACTOR, \
            1, \
            (IN_CLIP_SPACE_POS_Z - IN_CASCADE_END_CLIP_SPACE[1]) \
                / (IN_CASCADE_END_CLIP_SPACE[2] - IN_CASCADE_END_CLIP_SPACE[1])); \
    } \
}

struct ShadowResult {
    float shadowFactor;
    int cascadeIndex;
};

template<typename T>
ShadowResult calculateShadow(
    T fragmentIn,
    depth2d_array<float, access::sample> shadowTexture,
    sampler shadowSampler,
    constant float * cascadeEndClipSpace,
    bool enableShadows,
    constant SharedUniforms & uniformsShared
) {
    float csmShadowFactor = 1;
    int csmCascadeIndex = -1;

    if (enableShadows) {
        if (fragmentIn.clipSpacePosZ > cascadeEndClipSpace[${CASCADED_SHADOW_NUM_CASCADES} - 1]) {
            csmShadowFactor = 1;
        } else {
            REPEAT(
                ${CASCADED_SHADOW_NUM_CASCADES}, 
                CALCULATE_CSM_SHADOW_FACTOR, 
                fragmentIn.lightSpacePos_,
                fragmentIn.clipSpacePosZ,
                cascadeEndClipSpace,
                shadowTexture,
                shadowSampler,
                csmCascadeIndex,
                csmShadowFactor,
                uniformsShared)
        }
    }

    return {
        .shadowFactor = csmShadowFactor,
        .cascadeIndex = csmCascadeIndex,
    };
}
"""
}
