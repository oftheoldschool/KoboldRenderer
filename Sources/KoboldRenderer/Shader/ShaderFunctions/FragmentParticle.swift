public class FragmentShaderFunctionTemplateParticle: FragmentShaderFunctionTemplate {
    override public class var functionName: String { "particleFragment" }
    override public class var inputLayout: String { "FullFragmentInput" }

    override public class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "ColorPlusDepth"),
            .instancedColor: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "float4",
                attachmentLayout: "ColorPlusDepth"),

            .colorAlpha: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaFragmentOutput",
                attachmentLayout: "ColorPlusRevealagePlusDepth"),
            .instancedColorAlpha: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaFragmentOutput",
                attachmentLayout: "ColorPlusRevealagePlusDepth"),

            .colorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "BloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusDepth"),
            .instancedColorPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "BloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusDepth"),

            .colorAlphaPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaBloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusRevealagePlusDepth"),
            .instancedColorAlphaPlusBrightness: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusLightUniforms",
                outputLayout: "AlphaBloomFragmentOutput",
                attachmentLayout: "ColorPlusBrightnessPlusRevealagePlusDepth"),

            .gbuffer: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusMaterials",
                outputLayout: "GBufferFragmentOutput",
                attachmentLayout: "GBuffer"),
            .instancedGBuffer: FragmentShaderVariantLayouts(
                bufferLayout: "BaseUniformsPlusMaterials",
                outputLayout: "GBufferFragmentOutput",
                attachmentLayout: "GBuffer"),
        ]
    }

    override public class var textureLayout: String {
        "CascadedShadowMap"
    }

    override public class var materialLayout: String {
        "None"
    }

    override public class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
    constant MaterialUniforms & material = materials[uniformsObject.materialId];
    float2 uv = fragmentIn.texCoords * 2.0 - 1.0;
    float dist = length(uv);
    float circleAlpha = 1.0 - smoothstep(0.7, 1.0, dist);
    if (circleAlpha < 0.01) discard_fragment();
    float4 fragmentColor = float4(material.color.rgb, material.color.a * circleAlpha);
"""
    }

    override public class func getFragmentLightingCode(shaderVariant: FragmentFunctionVariant) -> String? {
        nil
    }

    override public class func getFragmentOutputCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
\(shaderVariant.isBloom
    ? (shaderVariant.isTransparency
        ? alphaBloomOutput
        : bloomOutput)
    : (shaderVariant.isGBuffer
        ? gbufferOutput
        : (shaderVariant.isTransparency
            ? alphaOutput
            : standardOutput)))
"""
    }

    override public class func getFragmentTransparencyCode(shaderVariant: FragmentFunctionVariant) -> String? {
        transparencyCode
    }

    private static let transparencyCode: String =
"""
    float4 preWeightColor = fragmentColor;
    float4 weightColor = fragmentColor;
    float transparencyWeight = max(
        min(
            1.0f,
            max(
                max(
                    weightColor.r,
                    weightColor.g),
                weightColor.b) * weightColor.a),
            weightColor.a) * clamp(0.03 / (1e-5 + pow(fragmentIn.clipSpacePosZ / 200, 4)),
        1e-2,
    3e3);

    float revealage = fragmentColor.a;
    fragmentColor = float4(fragmentColor.rgb * fragmentColor.a, fragmentColor.a) * transparencyWeight;

"""

    private static let standardOutput: String =
"""
    fragmentOut = fragmentColor;
"""

    private static let gbufferOutput: String =
"""
    fragmentOut = {
        .normal = float4(fragmentIn.worldNormal, 1),
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

    private static let alphaOutput: String =
"""
    fragmentOut = {
        .revealage = revealage,
        .color = fragmentColor,
    };
"""

    private static let alphaBloomOutput: String =
"""
    float4 brightness = calculateBloom(
        preWeightColor,
        uniformsShared.bloomThreshold,
        uniformsShared.bloomMultiplier
    );
    // Alpha-premultiply for OIT: the combine pass divides brightnessAlpha.rgb by
    // brightnessAlpha.a. With brightness.a tracking the fragment's actual alpha
    // (not contribution-scaled), dim transparents still contribute to the divisor
    // and attenuate bloom from brighter fragments behind them.
    brightness = float4(brightness.rgb * preWeightColor.a, preWeightColor.a);
    fragmentOut = {
        .revealage = revealage,
        .color = fragmentColor,
        .brightness = brightness,
    };
"""
}
