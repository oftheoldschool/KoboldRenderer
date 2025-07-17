import Metal
import simd

class ComputeShaderFunctionTemplateCombine: ComputeShaderFunctionTemplate {
    override class var functionName: String { "computeShaderCombine" }
    override class var perVariantLayouts: [ComputeFunctionVariant: ComputeShaderVariantLayouts] {
        [
            .color: ComputeShaderVariantLayouts(bufferLayout: "combine", textureLayout: "combine"),
            .colorPlusBloom: ComputeShaderVariantLayouts(bufferLayout: "combine", textureLayout: "combineBloom"),
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

    float4 finalColor = float4(mix(color.rgb, transparentColor, alpha), 1.0);
    float3 finalBloom = brightness.rgb + transparentBloom * alpha;

    textureComputeOutput.write(float4(finalColor.rgb + brightness.rgb, 1), gid);
""" : """
    float4 finalColor = float4(mix(color.rgb, transparentColor, alpha), 1.0);

    textureComputeOutput.write(float4(finalColor.rgb, 1), gid);
""")
    }
}
