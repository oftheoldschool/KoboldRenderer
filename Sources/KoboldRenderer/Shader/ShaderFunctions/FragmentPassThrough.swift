class FragmentShaderFunctionTemplatePassThrough: FragmentShaderFunctionTemplate {
    override class var functionName: String { "passThroughFragment" }
    override class var inputLayout: String { "FullFragmentInput" }
    override class var perVariantLayouts: [FragmentFunctionVariant: FragmentShaderVariantLayouts] {
        [
            .color: FragmentShaderVariantLayouts(
                bufferLayout: "None",
                outputLayout: "float4",
                attachmentLayout: "Color"),
        ]
    }
    override class var textureLayout: String {
        "PassThrough"
    }
    override class var materialLayout: String {
        "None"
    }

    override class func getFragmentCode(shaderVariant: FragmentFunctionVariant) -> String { "" }

    override class func getFragmentOutputCode(shaderVariant: FragmentFunctionVariant) -> String {
"""
    fragmentOut = texturePassThrough.sample(texturePassThroughSampler, fragmentIn.texCoords);
"""
    }
}

