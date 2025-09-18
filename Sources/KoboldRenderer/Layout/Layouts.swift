class LayoutLibrary {
    let vertexLayouts: [String: VertexLayout]
    let bufferLayouts: [String: BufferLayout]
    let textureLayouts: [String: TextureLayout]
    let materialLayouts: [String: MaterialLayout]
    let inOutLayouts: [String: InOutLayout]
    let uniformLayouts: [String: StructLayout]
    let attachmentLayouts: [String: AttachmentLayout]

    init(
        additionalVertexLayouts: [VertexLayout] = [],
        additionalBufferLayouts: [BufferLayout] = [],
        additionalTextureLayouts: [TextureLayout] = [],
        additionalMaterialLayouts: [MaterialLayout] = [],
        additionalInOutLayouts: [InOutLayout] = [],
        additionalUniformLayouts: [StructLayout] = [],
        additionalAttachmentLayouts: [AttachmentLayout] = []
    ) {
        self.vertexLayouts = (
            [
                VertexLayout(
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
                VertexLayout(
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
                VertexLayout(
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
            ] + additionalVertexLayouts
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.bufferLayouts = (
            [
                // vertex layouts

                // used for cascading shadow pass for static objects
                BufferLayout(
                    name: "BaseUniforms",
                    bufferLayoutBindings: [
                        Self.getBufferLayoutBinding(.uniformsShared),
                        Self.getBufferLayoutBinding(.uniformsObject),
                    ]
                ),

                // used for cascading shadow pass for animated objects
                BufferLayout(
                    name: "BaseUniformsPlusAnimation",
                    bufferLayoutBindings: [
                        Self.getBufferLayoutBinding(.uniformsShared),
                        Self.getBufferLayoutBinding(.uniformsObject),
                        Self.getBufferLayoutBinding(.uniformsAnimationPose),
                        Self.getBufferLayoutBinding(.uniformsAnimationInverseBindPose),
                    ]
                ),

                // used for regular color pass for static objects with light space volumes used to calculate which volume the vertex is in
                BufferLayout(
                    name: "BaseUniformsPlusLightSpaceVolumes",
                    bufferLayoutBindings: [
                        Self.getBufferLayoutBinding(.uniformsShared),
                        Self.getBufferLayoutBinding(.uniformsObject),
                        Self.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                    ]
                ),

                // used for regular color pass for animated objects with light space volumes used to calculate which volume the vertex is in
                BufferLayout(
                    name: "BaseUniformsPlusAnimationPlusLightSpaceVolumes",
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
                BufferLayout(
                    name: "BaseUniformsPlusMaterials",
                    bufferLayoutBindings: [
                        Self.getBufferLayoutBinding(.uniformsShared),
                        Self.getBufferLayoutBinding(.uniformsObject),
                        Self.getBufferLayoutBinding(.materials),
                    ]
                ),

                // used for shading fragments with lighting
                // object uniforms contain material id which is used to look up material
                BufferLayout(
                    name: "BaseUniformsPlusLightUniforms",
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
                BufferLayout(
                    name: "GBufferCombine",
                    bufferLayoutBindings: [
                        Self.getBufferLayoutBinding(.uniformsShared),
                        Self.getBufferLayoutBinding(.uniformsLights),
                        Self.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                        Self.getBufferLayoutBinding(.uniformsCascadeFrustumLimitsClipSpace),
                        Self.getBufferLayoutBinding(.materials),
                    ]
                ),

                BufferLayout(
                    name: "None",
                    bufferLayoutBindings: []
                ),
            ] + additionalBufferLayouts
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.textureLayouts = (
            [
                TextureLayout(
                    name: "CascadedShadowMap",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                    ]
                ),
                TextureLayout(
                    name: "PassThrough",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 1, type: .texturePassThrough, accessType: .sample),
                    ]
                ),
                TextureLayout(
                    name: "ComputeOutputTexture",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .sample),
                    ]
                ),
                TextureLayout(
                    name: "ComputeOutputBloomTexture",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 3, type: .textureComputeBloomOutput, accessType: .sample),
                    ]
                ),
                TextureLayout(
                    name: "DepthTexture",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .sample),
                    ]
                ),
                TextureLayout(
                    name: "GBufferNormals",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 6, type: .textureGBufferNormals, accessType: .sample),
                    ]
                ),
                TextureLayout(
                    name: "GBufferAlbedos",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 7, type: .textureGBufferAlbedos, accessType: .sample),
                    ]
                ),
                TextureLayout(
                    name: "GBufferCombine",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                        TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        TextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .read),
                        TextureLayoutBinding(index: 5, type: .textureGBufferNormals, accessType: .read),
                        TextureLayoutBinding(index: 6, type: .textureGBufferAlbedos, accessType: .read),
                    ]
                ),
                TextureLayout(
                    name: "GBufferCombineBloom",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                        TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        TextureLayoutBinding(index: 3, type: .textureComputeBloomOutput, accessType: .write),
                        TextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .read),
                        TextureLayoutBinding(index: 5, type: .textureGBufferNormals, accessType: .read),
                        TextureLayoutBinding(index: 6, type: .textureGBufferAlbedos, accessType: .read),
                    ]
                ),
                TextureLayout(
                    name: "Combine",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 1, type: .textureCombineRevealage, accessType: .read),
                        TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        TextureLayoutBinding(index: 3, type: .textureCombineColor, accessType: .read),
                        TextureLayoutBinding(index: 4, type: .textureCombineColorAlpha, accessType: .read),
                    ]
                ),
                TextureLayout(
                    name: "CombineBloom",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 1, type: .textureCombineRevealage, accessType: .read),
                        TextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        TextureLayoutBinding(index: 3, type: .textureCombineColor, accessType: .read),
                        TextureLayoutBinding(index: 4, type: .textureCombineColorAlpha, accessType: .read),
                        TextureLayoutBinding(index: 5, type: .textureCombineBrightness, accessType: .read),
                        TextureLayoutBinding(index: 6, type: .textureCombineBrightnessAlpha, accessType: .read),
                    ]
                ),
                TextureLayout(
                    name: "ConvertRGBA32FloatToBGRA8Unorm",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 0, type: .textureComputeInput, accessType: .read),
                        TextureLayoutBinding(index: 1, type: .textureComputeOutput, accessType: .write),
                    ]
                ),
                TextureLayout(
                    name: "None",
                    textureLayoutBindings: []
                ),
            ] + additionalTextureLayouts
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.materialLayouts = (
            [
                MaterialLayout(
                    name: "Textured",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 0, type: .textureBaseColor, accessType: .sample),
                    ]
                ),
                MaterialLayout(
                    name: "CubeTextured",
                    textureLayoutBindings: [
                        TextureLayoutBinding(index: 0, type: .textureCubeMap, accessType: .sample),
                    ]
                ),
                MaterialLayout(name: "None", textureLayoutBindings: []),
            ] + additionalMaterialLayouts
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.attachmentLayouts = (
            [
                AttachmentLayout(
                    name: "ColorPlusDepth",
                    colorAttachments: [
                        ColorAttachment(
                            description: "Color",
                            pixelFormat: .bgra8Unorm),
                    ],
                    depthAttachment: DepthAttachment(pixelFormat: .depth32)
                ),
                AttachmentLayout(
                    name: "ColorPlusRevealagePlusDepth",
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
                AttachmentLayout(
                    name: "ColorPlusBrightnessPlusDepth",
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
                AttachmentLayout(
                    name: "ColorPlusBrightnessPlusRevealagePlusDepth",
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
                AttachmentLayout(
                    name: "GBuffer",
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
                AttachmentLayout(
                    name: "Color",
                    colorAttachments: [
                        ColorAttachment(
                            description: "Color",
                            pixelFormat: .bgra8Unorm),
                    ],
                    depthAttachment: nil
                ),
                AttachmentLayout(
                    name: "Depth",
                    colorAttachments: [],
                    depthAttachment: DepthAttachment(pixelFormat: .depth32)
                ),
            ] + additionalAttachmentLayouts
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.uniformLayouts = ([
            StructLayout(
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
            StructLayout(
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
            StructLayout(
                name: "DrawObjectUniforms",
                items: [
                    StructItem(name: "model", type: .primitive(.float4x4)),
                    StructItem(name: "normalMatrix", type: .primitive(.float3x3)),
                    StructItem(name: "materialId", type: .primitive(.int)),
                ]
            ),
        ] + additionalUniformLayouts).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        // todo: separate fragment out layouts from vertex out/fragment in
        // also there's overlap between these and the attachments which were developed simultaneously
        self.inOutLayouts = (
            [
                .primitive(.float4),
                .compound(
                    StructLayout(
                        name: "BloomFragmentOutput",
                        items: [
                            StructItem(name: "color", type: .primitive(.float4), attributes: [.color(0)]),
                            StructItem(name: "brightness", type: .primitive(.float4), attributes: [.color(1)]),
                        ]
                    )
                ),
                .compound(
                    StructLayout(
                        name: "AlphaFragmentOutput",
                        items: [
                            StructItem(name: "revealage", type: .primitive(.float), attributes: [.color(0)]),
                            StructItem(name: "color", type: .primitive(.float4), attributes: [.color(1)]),
                        ]
                    )
                ),
                .compound(
                    StructLayout(
                        name: "AlphaBloomFragmentOutput",
                        items: [
                            StructItem(name: "revealage", type: .primitive(.float), attributes: [.color(0)]),
                            StructItem(name: "color", type: .primitive(.float4), attributes: [.color(1)]),
                            StructItem(name: "brightness", type: .primitive(.float4), attributes: [.color(2)]),
                        ]
                    )
                ),
                .compound(
                    StructLayout(
                        name: "GBufferFragmentOutput",
                        items: [
                            StructItem(name: "normal", type: .primitive(.float4), attributes: [.color(0)]),
                            StructItem(name: "albedo", type: .primitive(.float4), attributes: [.color(1)]),
                        ]
                    )
                ),
                .compound(
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
                .compound(
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
            ] + additionalInOutLayouts
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }
    }

    // todo: can/should this be incremented rather than hard coded? downside to hard coding is that
    // it's inflexible and error prone, but incrementing means that some optimisation opportunities
    // are a bit harder since you can't rely on the same buffer having the same binding across draw calls
    private static func getBufferLayoutBinding(_ bufferBindingType: KBufferBindingType) -> BufferLayoutBinding {
        return BufferLayoutBinding(index: bufferBindingType.bindingIndex, type: bufferBindingType)
    }
}
