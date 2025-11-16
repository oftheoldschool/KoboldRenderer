import Metal

protocol RenderStageOpaqueTechnique {
    func render(
        shaderLibrary: ShaderLibrary,
        dataBindings: [KBufferBindingType: GPUData],
        textureBindings: [KTextureBindingType: GPUTexture],
        rendererSettings: KRRendererSettings,
        renderPass: RenderPass,
        commandBuffer: MTLCommandBuffer,
        currentFrame: Int,
        elapsedTime: Float,
        camera: KRCamera,
        lightingData: LightingData,
        modelManager: ModelManager,
        globalMaterialId: Int,
        globalLightingColor: SIMD3<Float>,
        drawDataList: [DrawData],
        outputTargets: RenderStageOpaqueOutput)

    func resize(
        device: MTLDevice,
        outputDimensions: (width: Int, height: Int),
        rendererSettings: KRRendererSettings,
        outputTargets: RenderStageOpaqueOutput
    )
}
