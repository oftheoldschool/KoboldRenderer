class LayoutLibrary {
    let vertexLayouts: [String: VertexLayout]
    let bufferLayouts: [String: BufferLayout]
    let textureLayouts: [String: TextureLayout]
    let materialLayouts: [String: MaterialLayout]
    let attachmentLayouts: [String: AttachmentLayout]
    let inOutLayouts: [String: InOutLayout]
    let uniformLayouts: [String: StructLayout]

    init() {
        self.vertexLayouts = [
            "fullVertex": VertexLayout(
                name: "FullVertex",
                attributes: [
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributePosition),
                        type: .float3,
                        offset: 0),
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributeNormal),
                        type: .float3,
                        offset: 0),
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributeTexCoords),
                        type: .float2,
                        offset: 0),
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributeWeights),
                        type: .float4,
                        offset: 0),
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributeJoints),
                        type: .int4,
                        offset: 0),
                ]
            ),
            "basicVertex": VertexLayout(
                name: "BasicVertex",
                attributes: [
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributePosition),
                        type: .float3,
                        offset: 0),
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributeNormal),
                        type: .float3,
                        offset: 0),
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributeTexCoords),
                        type: .float2,
                        offset: 0),
                ]
            ),
            "skyboxVertex": VertexLayout(
                name: "SkyboxVertex",
                attributes: [
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributePosition),
                        type: .float3,
                        offset: 0),
                    VertexAttributeLayout(
                        binding: Self.getBufferLayoutBinding(.attributeNormal),
                        type: .float3,
                        offset: 0),
                ]
            ),
        ]

        self.bufferLayouts = [
            // vertex layouts

            // used for cascading shadow pass for static objects
            "baseUniforms": BufferLayout(
                bufferLayoutBindings: [
                    Self.getBufferLayoutBinding(.uniformsShared),
                    Self.getBufferLayoutBinding(.uniformsObject),
                ]
            ),

            // used for cascading shadow pass for animated objects
            "baseUniformsPlusAnimation": BufferLayout(
                bufferLayoutBindings: [
                    Self.getBufferLayoutBinding(.uniformsShared),
                    Self.getBufferLayoutBinding(.uniformsObject),
                    Self.getBufferLayoutBinding(.uniformsAnimationPose),
                    Self.getBufferLayoutBinding(.uniformsAnimationInverseBindPose),
                ]
            ),

            // used for regular color pass for static objects with light space volumes used to calculate which volume the vertex is in
            "baseUniformsPlusLightSpaceVolumes": BufferLayout(
                bufferLayoutBindings: [
                    Self.getBufferLayoutBinding(.uniformsShared),
                    Self.getBufferLayoutBinding(.uniformsObject),
                    Self.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                ]
            ),

            // used for regular color pass for animated objects with light space volumes used to calculate which volume the vertex is in
            "baseUniformsPlusAnimationPlusLightSpaceVolumes": BufferLayout(
                bufferLayoutBindings: [
                    Self.getBufferLayoutBinding(.uniformsShared),
                    Self.getBufferLayoutBinding(.uniformsObject),
                    Self.getBufferLayoutBinding(.uniformsAnimationPose),
                    Self.getBufferLayoutBinding(.uniformsAnimationInverseBindPose),
                    Self.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                ]
            ),

            // fragment layouts

            // used for shading fragments without lighting, for example in skybox or writing to gbuffer
            "baseUniformsPlusMaterials": BufferLayout(
                bufferLayoutBindings: [
                    Self.getBufferLayoutBinding(.uniformsShared),
                    Self.getBufferLayoutBinding(.uniformsObject),
                    Self.getBufferLayoutBinding(.materials),
                ]
            ),

            // used for shading fragments with lighting
            // object uniforms contain material id which is used to look up material
            "baseUniformsPlusLightUniforms": BufferLayout(
                bufferLayoutBindings: [
                    Self.getBufferLayoutBinding(.uniformsShared),
                    Self.getBufferLayoutBinding(.uniformsObject),
                    Self.getBufferLayoutBinding(.uniformsLights),
                    Self.getBufferLayoutBinding(.uniformsCascadeFrustumLimitsClipSpace),
                    Self.getBufferLayoutBinding(.materials),
                ]
            ),

            // used for shading fragments with lighting in the deferred pass
            // the albedo texture's alpha channel contains the material id which is used to look up material
            // light space volumes are required to calculate the cascade the fragment is in
            "gbufferCombine": BufferLayout(
                bufferLayoutBindings: [
                    Self.getBufferLayoutBinding(.uniformsShared),
                    Self.getBufferLayoutBinding(.uniformsLights),
                    Self.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                    Self.getBufferLayoutBinding(.uniformsCascadeFrustumLimitsClipSpace),
                    Self.getBufferLayoutBinding(.materials),
                ]
            ),

            // may not need any bindings for combine. adding shared uniforms for now
            "combine": BufferLayout(
                bufferLayoutBindings: [
                ]
            ),


            "none": BufferLayout(bufferLayoutBindings: []),
        ]

        self.textureLayouts = [
            // todo: indicate whether these are for read or write usage. Maybe have separate arrays?
            // todo: why are no textures bound to 0?
            "cascadedShadowMap": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                ]
            ),
            "passThrough": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 1, type: .texturePassThrough, accessType: .sample),
                ]
            ),
            "computeOutputTexture": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .sample),
                ]
            ),
            "computeOutputBloomTexture": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 3, type: .textureComputeBloomOutput, accessType: .sample),
                ]
            ),
            "depthTexture": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .sample),
                ]
            ),
            "gbufferNormals": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 6, type: .textureGBufferNormals, accessType: .sample),
                ]
            ),
            "gbufferAlbedos": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 7, type: .textureGBufferAlbedos, accessType: .sample),
                ]
            ),
            "gbufferCombine": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                    TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                    TextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .read),
                    TextureLayoutBinding(index: 5, type: .textureGBufferNormals, accessType: .read),
                    TextureLayoutBinding(index: 6, type: .textureGBufferAlbedos, accessType: .read),
                ]
            ),
            "gbufferCombineBloom": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                    TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                    TextureLayoutBinding(index: 3, type: .textureComputeBloomOutput, accessType: .write),
                    TextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .read),
                    TextureLayoutBinding(index: 5, type: .textureGBufferNormals, accessType: .read),
                    TextureLayoutBinding(index: 6, type: .textureGBufferAlbedos, accessType: .read),
                ]
            ),

            "combine": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 1, type: .textureCombineRevealage, accessType: .read),
                    TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                    TextureLayoutBinding(index: 3, type: .textureCombineColor, accessType: .read),
                    TextureLayoutBinding(index: 4, type: .textureCombineColorAlpha, accessType: .read),
                ]
            ),
            "combineBloom": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 1, type: .textureCombineRevealage, accessType: .read),
                    TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                    TextureLayoutBinding(index: 3, type: .textureCombineColor, accessType: .read),
                    TextureLayoutBinding(index: 4, type: .textureCombineColorAlpha, accessType: .read),
                    TextureLayoutBinding(index: 5, type: .textureCombineBrightness, accessType: .read),
                    TextureLayoutBinding(index: 6, type: .textureCombineBrightnessAlpha, accessType: .read),
                ]
            ),
            "convertRGBA32FloatToBGRA8Unorm": TextureLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 0, type: .textureComputeInput, accessType: .read),
                    TextureLayoutBinding(index: 1, type: .textureComputeOutput, accessType: .write),
                ]
            ),
            "none": TextureLayout(textureLayoutBindings: []),
        ]

        self.materialLayouts = [
            "textured": MaterialLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 0, type: .textureBaseColor, accessType: .sample),
                ]
            ),
            "cubeTextured": MaterialLayout(
                textureLayoutBindings: [
                    TextureLayoutBinding(index: 0, type: .textureCubeMap, accessType: .sample),
                ]
            ),
            "none": MaterialLayout(textureLayoutBindings: []),
        ]

        self.attachmentLayouts = [
            "colorPlusDepth": AttachmentLayout(
                colorAttachments: [
                    ColorAttachment(
                        description: "Color",
                        pixelFormat: .bgra8Unorm),
                ],
                depthAttachment: DepthAttachment(pixelFormat: .depth32)
            ),
            "colorPlusRevealagePlusDepth": AttachmentLayout(
                colorAttachments: [
                    ColorAttachment(
                        description: "Revealage",
                        pixelFormat: .r16Float,
                        enableTransparency: true),
                    ColorAttachment(
                        description: "Color Accumulation",
                        pixelFormat: .rgba16Float,
                        enableTransparency: true),
                ],
                depthAttachment: DepthAttachment(pixelFormat: .depth32)
            ),
            "colorPlusBrightnessPlusDepth": AttachmentLayout(
                colorAttachments: [
                    ColorAttachment(
                        description: "Color",
                        pixelFormat: .bgra8Unorm),
                    ColorAttachment(
                        description: "Brightness",
                        pixelFormat: .bgra8Unorm),
                ],
                depthAttachment: DepthAttachment(pixelFormat: .depth32)
            ),
            "colorPlusBrightnessPlusRevealagePlusDepth": AttachmentLayout(
                colorAttachments: [
                    ColorAttachment(
                        description: "Revealage",
                        pixelFormat: .r16Float,
                        enableTransparency: true),
                    ColorAttachment(
                        description: "Color Accumulation",
                        pixelFormat: .rgba16Float,
                        enableTransparency: true),
                    ColorAttachment(
                        description: "Brightness Accumulation",
                        pixelFormat: .rgba16Float,
                        enableTransparency: true),
                ],
                depthAttachment: DepthAttachment(pixelFormat: .depth32)
            ),
            "gbuffer": AttachmentLayout(
                colorAttachments: [
                    ColorAttachment(
                        description: "Albedo (xyz), MaterialId (w)",
                        pixelFormat: .rgba32Float),
                    ColorAttachment(
                        description: "Normal",
                        pixelFormat: .rgba32Float),
                ],
                depthAttachment: DepthAttachment(pixelFormat: .depth32)
            ),
            "color": AttachmentLayout(
                colorAttachments: [
                    ColorAttachment(
                        description: "Color",
                        pixelFormat: .bgra8Unorm),
                ],
                depthAttachment: nil
            ),
            "depth": AttachmentLayout(
                colorAttachments: [],
                depthAttachment: DepthAttachment(pixelFormat: .depth32)
            ),
        ]

        self.uniformLayouts = [
            "SharedUniforms": StructLayout(
                name: "SharedUniforms",
                items: [
                    StructItem(name: "viewProjection", type: .primitive(.float4x4)),
                    StructItem(name: "invViewProjection", type: .primitive(.float4x4)),
                    StructItem(name: "invViewMatrix", type: .primitive(.float4x4)),
                    StructItem(name: "invProjectionMatrix", type: .primitive(.float4x4)),
                    StructItem(name: "noTranslationViewProjection", type: .primitive(.float4x4)),
                    StructItem(name: "cameraPosition", type: .primitive(.float3)),
                    StructItem(name: "bloomThreshold", type: .primitive(.float3)),
                    StructItem(name: "bloomMultiplier", type: .primitive(.float3)),
                    StructItem(name: "globalLightingColor", type: .primitive(.float3)),
                    StructItem(name: "elapsedTime", type: .primitive(.float)),
                    StructItem(name: "globalMaterialId", type: .primitive(.int32_t)),
                    StructItem(name: "lightCount", type: .primitive(.uint8_t)),
                    StructItem(name: "enableShadows", type: .primitive(.bool)),
                    StructItem(name: "enableLighting", type: .primitive(.bool)),
                    StructItem(name: "enableFlatShading", type: .primitive(.bool)),
                ]
            ),
            "LightUniforms": StructLayout(
                name: "LightUniforms",
                items: [
                    StructItem(name: "float3Data", type: .primitive(.float3)),
                    StructItem(name: "intensity", type: .primitive(.float)),
                    StructItem(name: "color", type: .primitive(.float3)),
                    StructItem(name: "range", type: .primitive(.float)),
                    StructItem(name: "attenuation", type: .primitive(.float3)),
                    StructItem(name: "type", type: .custom("LightUniformsType")),
                ]
            ),
            "DrawObjectUniforms": StructLayout(
                name: "DrawObjectUniforms",
                items: [
                    StructItem(name: "model", type: .primitive(.float4x4)),
                    StructItem(name: "normalMatrix", type: .primitive(.float3x3)),
                    StructItem(name: "materialId", type: .primitive(.int)),
                ]
            ),
        ]

        // todo: separate fragment out layouts from vertex out/fragment in
        // also there's overlap between these and the attachments which were developed simultaneously
        self.inOutLayouts = [
            "float4": .primitive(.float4),
            "forwardBloom": .compound(
                StructLayout(
                    name: "BloomFragmentOutput",
                    items: [
                        StructItem(name: "color", type: .primitive(.float4), attributes: [.color(0)]),
                        StructItem(name: "brightness", type: .primitive(.float4), attributes: [.color(1)]),
                    ]
                )
            ),
            "alpha": .compound(
                StructLayout(
                    name: "AlphaFragmentOutput",
                    items: [
                        StructItem(name: "revealage", type: .primitive(.float), attributes: [.color(0)]),
                        StructItem(name: "color", type: .primitive(.float4), attributes: [.color(1)]),
                    ]
                )
            ),
            "alphaBloom": .compound(
                StructLayout(
                    name: "AlphaBloomFragmentOutput",
                    items: [
                        StructItem(name: "revealage", type: .primitive(.float), attributes: [.color(0)]),
                        StructItem(name: "color", type: .primitive(.float4), attributes: [.color(1)]),
                        StructItem(name: "brightness", type: .primitive(.float4), attributes: [.color(2)]),
                    ]
                )
            ),
            "gbuffer": .compound(
                StructLayout(
                    name: "GBufferFragmentOutput",
                    items: [
                        StructItem(name: "normal", type: .primitive(.float4), attributes: [.color(0)]),
                        StructItem(name: "albedo", type: .primitive(.float4), attributes: [.color(1)]),
                    ]
                )
            ),
            "fullFragment": .compound(
                StructLayout(
                    name: "FullFragmentInput",
                    items: [
                        StructItem(name: "position", type: .primitive(.float4), attributes: [.position]),
                        StructItem(name: "worldPosition", type: .primitive(.float3)),
                        StructItem(name: "worldNormal", type: .primitive(.float3)),
                        StructItem(name: "localPosition", type: .primitive(.float3)),
                        StructItem(name: "normal", type: .primitive(.float3)),
                        StructItem(
                            name: "lightSpacePos_",
                            type: .repeated(
                                RepeatedItemType(
                                    count: "${CASCADED_SHADOW_NUM_CASCADES}",
                                    type: .float4))),
                        StructItem(name: "texCoords", type: .primitive(.float2)),
                        StructItem(name: "clipSpacePosZ", type: .primitive(.float)),
                        StructItem(name: "instanceId", type: .primitive(.int))
                    ]
                )
            ),
            "shadowCalculationData": .compound(
                StructLayout(
                    name: "ShadowCalculationData",
                    items: [
                        StructItem(
                            name: "lightSpacePos_",
                            type: .repeated(
                                RepeatedItemType(
                                    count: "${CASCADED_SHADOW_NUM_CASCADES}",
                                    type: .float4))),
                        StructItem(name: "clipSpacePosZ", type: .primitive(.float)),
                    ]
                )
            ),
        ]
    }

    // todo: can/should this be incremented rather than hard coded? downside to hard coding is that
    // it's inflexible and error prone, but incrementing means that some optimisation opportunities
    // are a bit harder since you can't rely on the same buffer having the same binding across draw calls
    private static func getBufferLayoutBinding(_ bufferBindingType: KBufferBindingType) -> BufferLayoutBinding {
        switch bufferBindingType {
        case .attributePosition: BufferLayoutBinding(index: 0, type: bufferBindingType)
        case .attributeNormal: BufferLayoutBinding(index: 1, type: bufferBindingType)
        case .attributeTexCoords: BufferLayoutBinding(index: 2, type: bufferBindingType)
        case .attributeWeights: BufferLayoutBinding(index: 3, type: bufferBindingType)
        case .attributeJoints: BufferLayoutBinding(index: 4, type: bufferBindingType)
        case .uniformsShared: BufferLayoutBinding(index: 5, type: bufferBindingType)
        case .uniformsLights: BufferLayoutBinding(index: 6, type: bufferBindingType)
        case .uniformsObject: BufferLayoutBinding(index: 7, type: bufferBindingType)
        case .uniformsLightSpaceVolumes: BufferLayoutBinding(index: 8, type: bufferBindingType)
        case .uniformsCascadeFrustumLimitsClipSpace: BufferLayoutBinding(index: 9, type: bufferBindingType)
        case .uniformsAnimationPose: BufferLayoutBinding(index: 10, type: bufferBindingType)
        case .uniformsAnimationInverseBindPose: BufferLayoutBinding(index: 11, type: bufferBindingType)
        case .materials: BufferLayoutBinding(index: 12, type: bufferBindingType)
        }
    }
}
