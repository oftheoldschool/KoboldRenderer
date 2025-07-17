class FragmentShaderFunctionTemplateSkySphere: FragmentShaderFunctionTemplate {
    override class var functionName: String { "skysphereFragment" }
    override class var inputLayout: String { "basicFragment" }
    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "float4",
                attachmentLayout: "colorPlusDepth"),
            .colorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "forwardBloom",
                attachmentLayout: "colorPlusBrightnessPlusDepth"),
            .gbuffer: FragmentShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusMaterials",
                outputLayout: "gbuffer",
                attachmentLayout: "gbuffer")        ]
    }
    override class var textureLayout: String {
        "none"
    }
    override class var materialLayout: String {
        "none"
    }

    override class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
    constant MaterialUniforms & material = materials[uniformsObject.materialId];
    constant MaterialUniforms & globalMaterial = materials[uniformsShared.globalMaterialId];
    float3 spaceColor = material.color.rgb;

    FractalNoiseMetalParameters spaceNoiseParameters {
        .lacunarity = 2.7,
        .gain = 0.5,
        .startingAmplitude = 2,
        .startingFrequency = 0.05,
        .octaves = 6,
        .warpIterations = 1,
        .warpScale = 1,
        .coordinateScale = 25,
        .noiseType = FractalNoiseMetalType::openSimplex2,
        .noiseTypeParameters = {
            .openSimplex2Parameters = {
                .seed = 1337,
                .noise3Variant = OpenSimplex2MetalNoise3Variant::xz,
            },
        },
    };
    float spaceNoise = map3dNoiseToRange(
        fbm3Warp(spaceNoiseParameters, fragmentIn.worldPosition + uniformsShared.elapsedTime / 20),
        -0.9,
        1.2);

    FractalNoiseMetalParameters starNoiseParameters {
        .lacunarity = 0.08,
        .gain = 0.2,
        .startingAmplitude = 1.14,
        .startingFrequency = 0.1,
        .octaves = 1,
        .warpIterations = 1,
        .warpScale = 1,
        .coordinateScale = 800,
        .noiseType = FractalNoiseMetalType::openSimplex2,
        .noiseTypeParameters = {
            .openSimplex2Parameters = {
                .seed = 1973,
                .noise3Variant = OpenSimplex2MetalNoise3Variant::xz,
            },
        },
    };

    float starNoise = map3dNoiseToRange(
        fbm3Warp(starNoiseParameters, fragmentIn.worldPosition),
        -10,
        0.6);

    float3 stars = float3(clamp(starNoise, 0.4, 0.9) - 0.4) * 2;
    spaceColor *= spaceNoise;
    spaceColor = saturate(spaceColor + stars * 2);

    float4 resolvedColor = getResolvedColor(
        material,
        globalMaterial,
        fragmentIn.worldPosition,
        fragmentIn.worldNormal,
        0,
        spaceColor);

    float4 fragmentColor = float4(resolvedColor.rgb, 1);
"""
    }

    override class func getFragmentOutputCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
\(shaderVariant.isBloom ? bloomOutput : (shaderVariant.isGBuffer ? gbufferOutput : standardOutput))
"""
    }

    private static let standardOutput: String =
"""
    fragmentOut = fragmentColor;
"""

    private static let gbufferOutput: String =
"""
    fragmentOut = {
        .normal = float4(fragmentIn.normal, 1),
        .albedo = float4(fragmentColor.rgb, float(uniformsObject.materialId)),
    };
"""

    private static let bloomOutput: String =
"""
    float4 brightness = calculateBloom(
        fragmentColor,
        uniformsShared.bloomThreshold,
        uniformsShared.bloomMultiplier
    );
    fragmentOut = {
        .color = fragmentColor,
        .brightness = brightness,
    };
"""
}
