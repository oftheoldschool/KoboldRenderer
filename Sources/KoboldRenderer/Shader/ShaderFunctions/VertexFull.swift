class VertexShaderFunctionTemplateAnimation: VertexShaderFunctionTemplate {
    override class var functionName: String { "fullVertex" }
    override class var vertexLayout: String { "fullVertex" }
    override class var perVariantLayouts: [VertexFunctionVariant: VertexShaderVariantLayouts] {
        [
            .single: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightSpaceVolumes",
                outputLayout: "fullFragment"),
            .instanced: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusLightSpaceVolumes",
                outputLayout: "fullFragment"),
            .singleShadow: VertexShaderVariantLayouts(
                bufferLayout: "baseUniforms",
                outputLayout: "float4",
                attachmentLayout: "depth"),
            .instancedShadow: VertexShaderVariantLayouts(
                bufferLayout: "baseUniforms",
                outputLayout: "float4",
                attachmentLayout: "depth"),
            .singleAnimated: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusAnimationPlusLightSpaceVolumes",
                outputLayout: "fullFragment"),
            .instancedAnimated: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusAnimationPlusLightSpaceVolumes",
                outputLayout: "fullFragment"),
            .singleAnimatedShadow: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusAnimation",
                outputLayout: "float4",
                attachmentLayout: "depth"),
            .instancedAnimatedShadow: VertexShaderVariantLayouts(
                bufferLayout: "baseUniformsPlusAnimation",
                outputLayout: "float4",
                attachmentLayout: "depth"),
        ]
    }

    override class var vertexPositionCode: String {
"""
    float4 worldPosition = uniformsObject.model * float4(vertexIn.position, 1);
    float4x4 viewProjectionMatrix = uniformsShared.viewProjection;
    float4 outputPosition = viewProjectionMatrix * worldPosition;
    float3 worldNormal = uniformsObject.normalMatrix * vertexIn.normal;
"""
    }

    override class var vertexAnimationCode: String? {
"""
    float4x4 skin = float4x4(0);
    skin += (uniformsAnimationPose[vertexIn.joints.x] * uniformsAnimationInverseBindPose[vertexIn.joints.x]) * vertexIn.weights.x;
    skin += (uniformsAnimationPose[vertexIn.joints.y] * uniformsAnimationInverseBindPose[vertexIn.joints.y]) * vertexIn.weights.y;
    skin += (uniformsAnimationPose[vertexIn.joints.z] * uniformsAnimationInverseBindPose[vertexIn.joints.z]) * vertexIn.weights.z;
    skin += (uniformsAnimationPose[vertexIn.joints.w] * uniformsAnimationInverseBindPose[vertexIn.joints.w]) * vertexIn.weights.w;

    float4 worldPosition = uniformsObject.model * skin * float4(vertexIn.position, 1);
    float4x4 viewProjectionMatrix = uniformsShared.viewProjection;
    float4 outputPosition = viewProjectionMatrix * worldPosition;
    float3 worldNormal = normalize(uniformsObject.normalMatrix * upperLeft(skin) * vertexIn.normal);
"""
    }

    override class var vertexAdditionalCode: String? {
"""
    vertexOut.position = outputPosition;
    vertexOut.normal = vertexIn.normal;
    vertexOut.texCoords = vertexIn.texCoords;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = worldNormal;
    vertexOut.clipSpacePosZ = vertexOut.position.z;

    REPEAT(
        ${CASCADED_SHADOW_NUM_CASCADES}, 
        CALCULATE_LIGHTSPACE_POS, 
        worldPosition, 
        uniformsLightSpaceVolumes,
        vertexOut.lightSpacePos_)
"""
    }
}

