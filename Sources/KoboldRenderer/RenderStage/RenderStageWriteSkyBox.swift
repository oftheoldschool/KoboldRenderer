import Metal
import simd

public class RenderStageWriteSkyBox {
    func writeSkybox(
        device: MTLDevice,
        shaderLibrary: ShaderLibrary,
        gpuDataManager: GPUDataManager,
        modelManager: ModelManager,
        skyboxSize: Int,
        renderPass: RenderPass,
        commandBuffer: MTLCommandBuffer,
        drawDataList: [DrawData],
        materialBuffer: GPUDataBuffer,
        bloomThreshold: SIMD3<Float>,
        bloomMultiplier: SIMD3<Float>,
        elapsedTime: Float,
        rendererSettings: KRRendererSettings
    ) -> KRModelInput {
        let camParams: [(forward: SIMD3<Float>, up: SIMD3<Float>)] = [
            (.xPositive, .yPositive), (.xNegative, .yPositive),
            (.yPositive, .zPositive), (.yNegative, .zNegative),
            (.zNegative, .yPositive), (.zPositive, .yPositive),
        ]

        let cubeTextureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(
            pixelFormat: .bgra8Unorm,
            size: skyboxSize,
            mipmapped: false)
        cubeTextureDescriptor.usage = [.renderTarget, .shaderRead]
        cubeTextureDescriptor.storageMode = .private

        let cubeTexture = device.makeTexture(descriptor: cubeTextureDescriptor)!

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: skyboxSize,
            height: skyboxSize,
            mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDescriptor.storageMode = .private

        let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!
        depthTexture.label = "Skybox Depth Texture"

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = cubeTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(rendererSettings.clearColor)
        renderPassDescriptor.depthAttachment.texture = depthTexture

        for (index, camParam) in camParams.enumerated() {
            let (forward, up) = camParam
            let camera = KRCamera(
                volume: .perspective(
                    KRVolumePerspective(
                    near: 0.1,
                    far: 10,
                    aspectRatio: 1,
                    fov: .pi / 2)),
                position: .zero,
                direction: forward,
                up: up,
                leftHanded: true)
            renderPassDescriptor.colorAttachments[0].slice = index

            let sharedUniforms = SharedUniforms(
                camera: camera,
                elapsedTime: elapsedTime)

            let dataBindings: [KBufferBindingType: GPUData] = [
                .uniformsShared: .wrapper(GPUDataWrapper(sharedUniforms)),
                .materials: .buffer(materialBuffer),
            ]

            renderPass.render(
                shaderLibrary: shaderLibrary,
                modelManager: modelManager,
                commandBuffer: commandBuffer,
                outputRenderPassDescriptor: renderPassDescriptor,
                drawDataList: drawDataList,
                dataBindings: dataBindings,
                currentFrame: 0,
                renderTarget: .colorPlusDepth,
                rendererSettings: rendererSettings)
        }

        return getSkybox(
            device: device,
            modelManager: modelManager,
            cubeTexture: cubeTexture
        )
    }

    private func getSkybox(
        device: MTLDevice,
        modelManager: ModelManager,
        cubeTexture: MTLTexture
    ) -> KRModelInput {
        let samplerStateDescriptor = MTLSamplerDescriptor()
        samplerStateDescriptor.magFilter = .linear
        samplerStateDescriptor.minFilter = .linear
        let sampler = device.makeSamplerState(descriptor: samplerStateDescriptor)!

        let boundingBox = KBoundingBox(Self.cubePositions)
        let modelInput = KRModelInput(
            name: "skyBox",
            meshInput: [
                KMeshInput(
                    verticesData: [
                        (.attributePosition, MemoryLayout<Float>.size * 3, Self.cubePositions.toByteArray()),
                        (.attributeNormal, MemoryLayout<Float>.size * 3, Self.cubeNormals.toByteArray()),
                    ],
                    vertexCount: Self.cubePositions.count,
                    indexData: (KIndexType.uint32, MemoryLayout<UInt32>.size, Self.cubeIndices.toByteArray()),
                    indexCount: Self.cubeIndices.count,
                    textures: [.textureCubeMap: "skyBox"],
                    primitiveType: .triangle,
                    boundingBox: boundingBox)
            ],
            textures: [
                "skyBox": .gpu(texture: cubeTexture, sampler: sampler)
            ]
        )

        modelManager.loadModel(modelInput: modelInput)
        return modelInput
    }

    private static let cubePositions = [
        SIMD3<Float>( 1.0, -1.0,  1.0), SIMD3<Float>( 1.0, -1.0, -1.0), SIMD3<Float>( 1.0,  1.0, -1.0), SIMD3<Float>( 1.0,  1.0,  1.0),
        SIMD3<Float>(-1.0, -1.0,  1.0), SIMD3<Float>(-1.0,  1.0,  1.0), SIMD3<Float>(-1.0,  1.0, -1.0), SIMD3<Float>(-1.0, -1.0, -1.0),
        SIMD3<Float>( 1.0,  1.0, -1.0), SIMD3<Float>(-1.0,  1.0, -1.0), SIMD3<Float>(-1.0,  1.0,  1.0), SIMD3<Float>( 1.0,  1.0,  1.0),
        SIMD3<Float>( 1.0, -1.0,  1.0), SIMD3<Float>(-1.0, -1.0,  1.0), SIMD3<Float>(-1.0, -1.0, -1.0), SIMD3<Float>( 1.0, -1.0, -1.0),
        SIMD3<Float>( 1.0,  1.0, -1.0), SIMD3<Float>( 1.0, -1.0, -1.0), SIMD3<Float>(-1.0, -1.0, -1.0), SIMD3<Float>(-1.0,  1.0, -1.0),
        SIMD3<Float>(-1.0,  1.0,  1.0), SIMD3<Float>(-1.0, -1.0,  1.0), SIMD3<Float>( 1.0, -1.0,  1.0), SIMD3<Float>( 1.0,  1.0,  1.0),
    ]

    private static let cubeNormals = [
        SIMD3<Float>( 1.0,  0.0,  0.0), SIMD3<Float>( 1.0,  0.0,  0.0), SIMD3<Float>( 1.0,  0.0,  0.0), SIMD3<Float>( 1.0,  0.0,  0.0),
        SIMD3<Float>(-1.0,  0.0,  0.0), SIMD3<Float>(-1.0,  0.0,  0.0), SIMD3<Float>(-1.0,  0.0,  0.0), SIMD3<Float>(-1.0,  0.0,  0.0),
        SIMD3<Float>( 0.0,  1.0,  0.0), SIMD3<Float>( 0.0,  1.0,  0.0), SIMD3<Float>( 0.0,  1.0,  0.0), SIMD3<Float>( 0.0,  1.0,  0.0),
        SIMD3<Float>( 0.0, -1.0,  0.0), SIMD3<Float>( 0.0, -1.0,  0.0), SIMD3<Float>( 0.0, -1.0,  0.0), SIMD3<Float>( 0.0, -1.0,  0.0),
        SIMD3<Float>( 0.0,  0.0, -1.0), SIMD3<Float>( 0.0,  0.0, -1.0), SIMD3<Float>( 0.0,  0.0, -1.0), SIMD3<Float>( 0.0,  0.0, -1.0),
        SIMD3<Float>( 0.0,  0.0,  1.0), SIMD3<Float>( 0.0,  0.0,  1.0), SIMD3<Float>( 0.0,  0.0,  1.0), SIMD3<Float>( 0.0,  0.0,  1.0),
    ].map { -$0 }

    private static let cubeIndices: [UInt32] = [
        0,  2,  1,  0,  3,  2,
        4,  6,  5,  4,  7,  6,
        8, 10,  9,  8,  11, 10,
        12, 14, 13, 12, 15, 14,
        16, 18, 17, 16, 19, 18,
        20, 22, 21, 20, 23, 22,
    ]
}
