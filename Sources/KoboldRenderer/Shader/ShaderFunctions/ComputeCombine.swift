import Metal
import simd

class ComputeShaderFunctionTemplateCombine: ComputeShaderFunctionTemplate {
    override class var functionName: String { "computeShaderCombine" }
    override class var perVariantLayouts: [ComputeFunctionVariant: ComputeShaderVariantLayouts] {
        [
            .color: ComputeShaderVariantLayouts(bufferLayout: "None", textureLayout: "Combine"),
            .colorPlusBloom: ComputeShaderVariantLayouts(bufferLayout: "None", textureLayout: "CombineBloom"),
        ]
    }
    override class var textureSizeValidation: Bool { true }
    override class func getComputeCode(shaderVariant: ComputeFunctionVariant) -> String {
"""
    float4 color = textureCombineColor.read(gid);
    float4 colorAlpha = textureCombineColorAlpha.read(gid);
    float3 transparentColor = colorAlpha.rgb / max(colorAlpha.a, 0.00001);

    float revealage = textureCombineRevealage.read(gid).r;
    float alpha = 1.0 - revealage;

""" + (shaderVariant.isBloom ? """
    float4 brightness = textureCombineBrightness.read(gid);
    float4 brightnessAlpha = textureCombineBrightnessAlpha.read(gid);

    float3 opaqueBloom = brightness.rgb;
    float3 transparentBloom = brightnessAlpha.rgb / max(brightnessAlpha.a, 0.00001);

    // Halo mask: use the smaller of original and blurred revealage so that
    // (a) on-geometry pixels keep full mask strength (distant/small transparent
    // objects don't lose intensity to blur dilution), and (b) pixels just outside
    // geometry — where blurred revealage dropped below 1 — still let bloom through.
    float revealageBlurred = textureCombineRevealageBlurred.read(gid).r;
    float bloomMask = 1.0 - min(revealage, revealageBlurred);

    // Depth-aware opaque bloom: shaders that opt in pack NDC depth into
    // brightness.a, so the blurred brightness texture carries averaged source
    // depth alongside averaged colour. Mask bloom where the local opaque depth
    // is significantly closer (higher in reverse-Z) than the blurred source
    // depth — that's a closer occluder catching bloom that should have stayed
    // behind it. Legacy shaders write alpha=1 (closest in reverse-Z), which
    // keeps the comparison passing everywhere and preserves prior behaviour.
    float opaqueDepth = textureCombineOpaqueDepth.read(gid);
    float bloomSourceDepth = brightness.a;
    // Wider smoothstep range gives a softer falloff at occluder silhouettes —
    // narrow values produced a visible hard arc where the bloom cuts off at a
    // planet's edge.
    float opaqueBloomVisibility = 1.0 - smoothstep(
        bloomSourceDepth + 0.002,
        bloomSourceDepth + 0.08,
        opaqueDepth);

    float4 finalColor = float4(mix(color.rgb, transparentColor, alpha), 1.0);
    float3 finalBloom = brightness.rgb * opaqueBloomVisibility + transparentBloom * bloomMask;

    textureComputeOutput.write(float4(finalColor.rgb + finalBloom, 1), gid);
""" : """
    float4 finalColor = float4(mix(color.rgb, transparentColor, alpha), 1.0);

    textureComputeOutput.write(float4(finalColor.rgb, 1), gid);
""")
    }
}
