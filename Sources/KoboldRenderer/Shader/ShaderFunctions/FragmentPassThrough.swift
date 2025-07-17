class FragmentShaderFunctionTemplatePassThrough: FragmentShaderFunctionTemplate {
    override class var functionName: String { "passThroughFragment" }
    override class var inputLayout: String { "basicFragment" }
    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "none",
                outputLayout: "float4",
                attachmentLayout: "color"),
        ]
    }
    override class var textureLayout: String {
        "passThrough"
    }
    override class var materialLayout: String {
        "none"
    }

    override class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String { "" }

    override class func getFragmentOutputCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
    fragmentOut = texturePassThrough.sample(texturePassThroughSampler, fragmentIn.texCoords);
"""
    }
}

