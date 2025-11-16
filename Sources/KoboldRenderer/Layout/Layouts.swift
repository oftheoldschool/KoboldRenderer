public struct KRendererLayouts: Sendable {
    public let vertexLayouts: [KVertexLayout]
    public let bufferLayouts: [KBufferLayout]
    public let textureLayouts: [KTextureLayout]
    public let materialLayouts: [KMaterialLayout]
    public let inOutLayouts: [KInOutLayout]
    public let uniformLayouts: [KStructLayout]
    public let attachmentLayouts: [KAttachmentLayout]

    public init(
        vertexLayouts: [KVertexLayout] = [],
        bufferLayouts: [KBufferLayout] = [],
        textureLayouts: [KTextureLayout] = [],
        materialLayouts: [KMaterialLayout] = [],
        inOutLayouts: [KInOutLayout] = [],
        uniformLayouts: [KStructLayout] = [],
        attachmentLayouts: [KAttachmentLayout] = []
    ) {
        self.vertexLayouts = vertexLayouts
        self.bufferLayouts = bufferLayouts
        self.textureLayouts  = textureLayouts
        self.materialLayouts = materialLayouts
        self.inOutLayouts = inOutLayouts
        self.uniformLayouts = uniformLayouts
        self.attachmentLayouts = attachmentLayouts
    }
}

public class LayoutLibrary {
    public let vertexLayouts: [String: KVertexLayout]
    public let bufferLayouts: [String: KBufferLayout]
    public let textureLayouts: [String: KTextureLayout]
    public let materialLayouts: [String: KMaterialLayout]
    public let inOutLayouts: [String: KInOutLayout]
    public let uniformLayouts: [String: KStructLayout]
    public let attachmentLayouts: [String: KAttachmentLayout]

    public init(
        additionalLayouts: KRendererLayouts? = nil
    ) {
        self.vertexLayouts = (
            Self.coreLayouts.vertexLayouts + (additionalLayouts?.vertexLayouts ?? [])
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.bufferLayouts = (
            Self.coreLayouts.bufferLayouts + (additionalLayouts?.bufferLayouts ?? [])
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.textureLayouts = (
            Self.coreLayouts.textureLayouts + (additionalLayouts?.textureLayouts ?? [])
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.materialLayouts = (
            Self.coreLayouts.materialLayouts + (additionalLayouts?.materialLayouts ?? [])
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.attachmentLayouts = (
            Self.coreLayouts.attachmentLayouts + (additionalLayouts?.attachmentLayouts ?? [])
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.uniformLayouts = (
            Self.coreLayouts.uniformLayouts + (additionalLayouts?.uniformLayouts ?? [])
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }

        self.inOutLayouts = (
            Self.coreLayouts.inOutLayouts + (additionalLayouts?.inOutLayouts ?? [])
        ).reduce(into: [:]) { acc, next in
            acc[next.name] = next
        }
    }

    public static var coreLayouts: KRendererLayouts {
        KRendererLayouts(
            vertexLayouts: [
                KVertexLayout(
                    name: "FullVertex",
                    attributes: [
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributePosition),
                            type: .float3,
                            offset: 0),
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributeNormal),
                            type: .float3,
                            offset: 0),
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributeTexCoords),
                            type: .float2,
                            offset: 0),
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributeWeights),
                            type: .float4,
                            offset: 0),
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributeJoints),
                            type: .int4,
                            offset: 0),
                    ]
                ),
                KVertexLayout(
                    name: "BasicVertex",
                    attributes: [
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributePosition),
                            type: .float3,
                            offset: 0),
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributeNormal),
                            type: .float3,
                            offset: 0),
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributeTexCoords),
                            type: .float2,
                            offset: 0),
                    ]
                ),
                KVertexLayout(
                    name: "SkyboxVertex",
                    attributes: [
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributePosition),
                            type: .float3,
                            offset: 0),
                        KVertexAttributeLayout(
                            binding: LayoutLibrary.getBufferLayoutBinding(.attributeNormal),
                            type: .float3,
                            offset: 0),
                    ]
                ),
            ],
            bufferLayouts: [
                // vertex layouts

                // used for cascading shadow pass for static objects
                KBufferLayout(
                    name: "BaseUniforms",
                    bufferLayoutBindings: [
                        LayoutLibrary.getBufferLayoutBinding(.uniformsShared),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsObject),
                    ]
                ),

                // used for cascading shadow pass for animated objects
                KBufferLayout(
                    name: "BaseUniformsPlusAnimation",
                    bufferLayoutBindings: [
                        LayoutLibrary.getBufferLayoutBinding(.uniformsShared),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsObject),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsAnimationPose),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsAnimationInverseBindPose),
                    ]
                ),

                // used for regular color pass for static objects with light space volumes used to calculate which volume the vertex is in
                KBufferLayout(
                    name: "BaseUniformsPlusLightSpaceVolumes",
                    bufferLayoutBindings: [
                        LayoutLibrary.getBufferLayoutBinding(.uniformsShared),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsObject),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                    ]
                ),

                // used for regular color pass for animated objects with light space volumes used to calculate which volume the vertex is in
                KBufferLayout(
                    name: "BaseUniformsPlusAnimationPlusLightSpaceVolumes",
                    bufferLayoutBindings: [
                        LayoutLibrary.getBufferLayoutBinding(.uniformsShared),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsObject),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsAnimationPose),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsAnimationInverseBindPose),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                    ]
                ),

                // fragment layouts

                // used for shading fragments without lighting, for example in skybox or writing to gbuffer
                KBufferLayout(
                    name: "BaseUniformsPlusMaterials",
                    bufferLayoutBindings: [
                        LayoutLibrary.getBufferLayoutBinding(.uniformsShared),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsObject),
                        LayoutLibrary.getBufferLayoutBinding(.materials),
                    ]
                ),

                // used for shading fragments with lighting
                // object uniforms contain material id which is used to look up material
                KBufferLayout(
                    name: "BaseUniformsPlusLightUniforms",
                    bufferLayoutBindings: [
                        LayoutLibrary.getBufferLayoutBinding(.uniformsShared),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsObject),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsLights),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsOccluders),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsLighting),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsCascadeFrustumLimitsClipSpace),
                        LayoutLibrary.getBufferLayoutBinding(.materials),
                    ]
                ),

                // used for shading fragments with lighting in the deferred pass
                // the albedo texture's alpha channel contains the material id which is used to look up material
                // light space volumes are required to calculate the cascade the fragment is in
                KBufferLayout(
                    name: "GBufferCombine",
                    bufferLayoutBindings: [
                        LayoutLibrary.getBufferLayoutBinding(.uniformsShared),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsLights),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsOccluders),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsLighting),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsLightSpaceVolumes),
                        LayoutLibrary.getBufferLayoutBinding(.uniformsCascadeFrustumLimitsClipSpace),
                        LayoutLibrary.getBufferLayoutBinding(.materials),
                    ]
                ),

                KBufferLayout(
                    name: "None",
                    bufferLayoutBindings: []
                ),
            ],
            textureLayouts: [
                KTextureLayout(
                    name: "CascadedShadowMap",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                    ]
                ),
                KTextureLayout(
                    name: "PassThrough",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 1, type: .texturePassThrough, accessType: .sample),
                    ]
                ),
                KTextureLayout(
                    name: "ComputeOutputTexture",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .sample),
                    ]
                ),
                KTextureLayout(
                    name: "ComputeOutputBloomTexture",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 3, type: .textureComputeBloomOutput, accessType: .sample),
                    ]
                ),
                KTextureLayout(
                    name: "DepthTexture",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .sample),
                    ]
                ),
                KTextureLayout(
                    name: "GBufferNormals",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 6, type: .textureGBufferNormals, accessType: .sample),
                    ]
                ),
                KTextureLayout(
                    name: "GBufferAlbedos",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 7, type: .textureGBufferAlbedos, accessType: .sample),
                    ]
                ),
                KTextureLayout(
                    name: "GBufferCombine",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                        KTextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        KTextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .read),
                        KTextureLayoutBinding(index: 5, type: .textureGBufferNormals, accessType: .read),
                        KTextureLayoutBinding(index: 6, type: .textureGBufferAlbedos, accessType: .read),
                    ]
                ),
                KTextureLayout(
                    name: "GBufferCombineBloom",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 1, type: .textureArrayCascadedShadowMap, accessType: .sample),
                        KTextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        KTextureLayoutBinding(index: 3, type: .textureComputeBloomOutput, accessType: .write),
                        KTextureLayoutBinding(index: 4, type: .textureGBufferDepth, accessType: .read),
                        KTextureLayoutBinding(index: 5, type: .textureGBufferNormals, accessType: .read),
                        KTextureLayoutBinding(index: 6, type: .textureGBufferAlbedos, accessType: .read),
                    ]
                ),
                KTextureLayout(
                    name: "Combine",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 1, type: .textureCombineRevealage, accessType: .read),
                        KTextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        KTextureLayoutBinding(index: 3, type: .textureCombineColor, accessType: .read),
                        KTextureLayoutBinding(index: 4, type: .textureCombineColorAlpha, accessType: .read),
                    ]
                ),
                KTextureLayout(
                    name: "CombineBloom",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 1, type: .textureCombineRevealage, accessType: .read),
                        KTextureLayoutBinding(index: 2, type: .textureComputeOutput, accessType: .write),
                        KTextureLayoutBinding(index: 3, type: .textureCombineColor, accessType: .read),
                        KTextureLayoutBinding(index: 4, type: .textureCombineColorAlpha, accessType: .read),
                        KTextureLayoutBinding(index: 5, type: .textureCombineBrightness, accessType: .read),
                        KTextureLayoutBinding(index: 6, type: .textureCombineBrightnessAlpha, accessType: .read),
                    ]
                ),
                KTextureLayout(
                    name: "ConvertRGBA32FloatToBGRA8Unorm",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 0, type: .textureComputeInput, accessType: .read),
                        KTextureLayoutBinding(index: 1, type: .textureComputeOutput, accessType: .write),
                    ]
                ),
                KTextureLayout(
                    name: "None",
                    textureLayoutBindings: []
                ),
            ],
            materialLayouts: [
                KMaterialLayout(
                    name: "Textured",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 0, type: .textureBaseColor, accessType: .sample),
                    ]
                ),
                KMaterialLayout(
                    name: "CubeTextured",
                    textureLayoutBindings: [
                        KTextureLayoutBinding(index: 0, type: .textureCubeMap, accessType: .sample),
                    ]
                ),
                KMaterialLayout(name: "None", textureLayoutBindings: []),
            ],
            inOutLayouts: [
                .primitive(.float4),
                .compound(
                    KStructLayout(
                        name: "BloomFragmentOutput",
                        items: [
                            KStructItem(name: "color", type: .primitive(.float4), attributes: [.color(0)]),
                            KStructItem(name: "brightness", type: .primitive(.float4), attributes: [.color(1)]),
                        ]
                    )
                ),
                .compound(
                    KStructLayout(
                        name: "AlphaFragmentOutput",
                        items: [
                            KStructItem(name: "revealage", type: .primitive(.float), attributes: [.color(0)]),
                            KStructItem(name: "color", type: .primitive(.float4), attributes: [.color(1)]),
                        ]
                    )
                ),
                .compound(
                    KStructLayout(
                        name: "AlphaBloomFragmentOutput",
                        items: [
                            KStructItem(name: "revealage", type: .primitive(.float), attributes: [.color(0)]),
                            KStructItem(name: "color", type: .primitive(.float4), attributes: [.color(1)]),
                            KStructItem(name: "brightness", type: .primitive(.float4), attributes: [.color(2)]),
                        ]
                    )
                ),
                .compound(
                    KStructLayout(
                        name: "GBufferFragmentOutput",
                        items: [
                            KStructItem(name: "normal", type: .primitive(.float4), attributes: [.color(0)]),
                            KStructItem(name: "albedo", type: .primitive(.float4), attributes: [.color(1)]),
                        ]
                    )
                ),
                .compound(
                    KStructLayout(
                        name: "FullFragmentInput",
                        items: [
                            KStructItem(name: "position", type: .primitive(.float4), attributes: [.position]),
                            KStructItem(name: "worldPosition", type: .primitive(.float3)),
                            KStructItem(name: "worldNormal", type: .primitive(.float3)),
                            KStructItem(name: "localPosition", type: .primitive(.float3)),
                            KStructItem(name: "normal", type: .primitive(.float3)),
                            KStructItem(
                                name: "lightSpacePos_",
                                type: .repeated(
                                    KRepeatedItemType(
                                        count: "${CASCADED_SHADOW_NUM_CASCADES}",
                                        type: .float4))),
                            KStructItem(name: "texCoords", type: .primitive(.float2)),
                            KStructItem(name: "clipSpacePosZ", type: .primitive(.float)),
                            KStructItem(name: "instanceId", type: .primitive(.int))
                        ]
                    )
                ),
                .compound(
                    KStructLayout(
                        name: "ShadowCalculationData",
                        items: [
                            KStructItem(name: "worldPosition", type: .primitive(.float3)),
                            KStructItem(
                                name: "lightSpacePos_",
                                type: .repeated(
                                    KRepeatedItemType(
                                        count: "${CASCADED_SHADOW_NUM_CASCADES}",
                                        type: .float4))),
                            KStructItem(name: "clipSpacePosZ", type: .primitive(.float)),
                        ]
                    )
                ),
            ],
            uniformLayouts: [
                KStructLayout(
                    name: "SharedUniforms",
                    items: [
                        KStructItem(name: "viewProjection", type: .primitive(.float4x4)),
                        KStructItem(name: "invViewProjection", type: .primitive(.float4x4)),
                        KStructItem(name: "invViewMatrix", type: .primitive(.float4x4)),
                        KStructItem(name: "invProjectionMatrix", type: .primitive(.float4x4)),
                        KStructItem(name: "noTranslationViewProjection", type: .primitive(.float4x4)),
                        KStructItem(name: "cameraPosition", type: .primitive(.float3)),
                        KStructItem(name: "bloomThreshold", type: .primitive(.float3)),
                        KStructItem(name: "bloomMultiplier", type: .primitive(.float3)),
                        KStructItem(name: "elapsedTime", type: .primitive(.float)),
                        KStructItem(name: "globalMaterialId", type: .primitive(.int32_t)),
                        KStructItem(name: "enableFlatShading", type: .primitive(.bool)),
                    ]
                ),
                KStructLayout(
                    name: "LightingUniforms",
                    items: [
                        KStructItem(name: "globalLightingColor", type: .primitive(.float3)),
                        KStructItem(name: "shadowNormalBias", type: .primitive(.float)),
                        KStructItem(name: "shadowBiasAngleFactor", type: .primitive(.float)),
                        KStructItem(name: "shadowCascadeFactor", type: .primitive(.float)),
                        KStructItem(name: "lightCount", type: .primitive(.uint8_t)),
                        KStructItem(name: "occluderCount", type: .primitive(.uint8_t)),
                        KStructItem(name: "enableShadows", type: .primitive(.bool)),
                        KStructItem(name: "enableLighting", type: .primitive(.bool)),
                    ]
                ),
                KStructLayout(
                    name: "LightUniforms",
                    items: [
                        KStructItem(name: "float3Data", type: .primitive(.float3)),
                        KStructItem(name: "intensity", type: .primitive(.float)),
                        KStructItem(name: "color", type: .primitive(.float3)),
                        KStructItem(name: "range", type: .primitive(.float)),
                        KStructItem(name: "attenuation", type: .primitive(.float3)),
                        KStructItem(name: "radius", type: .primitive(.float)),
                        KStructItem(name: "type", type: .custom("LightUniformsType")),
                    ]
                ),
                KStructLayout(
                    name: "OccluderUniforms",
                    items: [
                        KStructItem(name: "position", type: .primitive(.float3)),
                        KStructItem(name: "radius", type: .primitive(.float)),
                        KStructItem(name: "penumbraFactor", type: .primitive(.float)),
                        KStructItem(name: "sharpness", type: .primitive(.float)),
                    ]
                ),
                KStructLayout(
                    name: "DrawObjectUniforms",
                    items: [
                        KStructItem(name: "model", type: .primitive(.float4x4)),
                        KStructItem(name: "normalMatrix", type: .primitive(.float3x3)),
                        KStructItem(name: "materialId", type: .primitive(.int))
                    ]
                ),
            ],
            attachmentLayouts: [
                KAttachmentLayout(
                    name: "ColorPlusDepth",
                    colorAttachments: [
                        KColorAttachment(
                            description: "Color",
                            pixelFormat: .bgra8Unorm),
                    ],
                    depthAttachment: KDepthAttachment(pixelFormat: .depth32)
                ),
                KAttachmentLayout(
                    name: "ColorPlusRevealagePlusDepth",
                    colorAttachments: [
                        KColorAttachment(
                            description: "Revealage",
                            pixelFormat: .r16Float,
                            enableTransparency: true),
                        KColorAttachment(
                            description: "Color Accumulation",
                            pixelFormat: .rgba16Float,
                            enableTransparency: true),
                    ],
                    depthAttachment: KDepthAttachment(pixelFormat: .depth32)
                ),
                KAttachmentLayout(
                    name: "ColorPlusBrightnessPlusDepth",
                    colorAttachments: [
                        KColorAttachment(
                            description: "Color",
                            pixelFormat: .bgra8Unorm),
                        KColorAttachment(
                            description: "Brightness",
                            pixelFormat: .bgra8Unorm),
                    ],
                    depthAttachment: KDepthAttachment(pixelFormat: .depth32)
                ),
                KAttachmentLayout(
                    name: "ColorPlusBrightnessPlusRevealagePlusDepth",
                    colorAttachments: [
                        KColorAttachment(
                            description: "Revealage",
                            pixelFormat: .r16Float,
                            enableTransparency: true),
                        KColorAttachment(
                            description: "Color Accumulation",
                            pixelFormat: .rgba16Float,
                            enableTransparency: true),
                        KColorAttachment(
                            description: "Brightness Accumulation",
                            pixelFormat: .rgba16Float,
                            enableTransparency: true),
                    ],
                    depthAttachment: KDepthAttachment(pixelFormat: .depth32)
                ),
                KAttachmentLayout(
                    name: "GBuffer",
                    colorAttachments: [
                        KColorAttachment(
                            description: "Albedo (xyz), MaterialId (w)",
                            pixelFormat: .rgba32Float),
                        KColorAttachment(
                            description: "Normal",
                            pixelFormat: .rgba32Float),
                    ],
                    depthAttachment: KDepthAttachment(pixelFormat: .depth32)
                ),
                KAttachmentLayout(
                    name: "Color",
                    colorAttachments: [
                        KColorAttachment(
                            description: "Color",
                            pixelFormat: .bgra8Unorm),
                    ],
                    depthAttachment: nil
                ),
                KAttachmentLayout(
                    name: "Depth",
                    colorAttachments: [],
                    depthAttachment: KDepthAttachment(pixelFormat: .depth32)
                ),
            ]
        )
    }

    // todo: can/should this be incremented rather than hard coded? downside to hard coding is that
    // it's inflexible and error prone, but incrementing means that some optimisation opportunities
    // are a bit harder since you can't rely on the same buffer having the same binding across draw calls
    private static func getBufferLayoutBinding(_ bufferBindingType: KBufferBindingType) -> KBufferLayoutBinding {
        return KBufferLayoutBinding(index: bufferBindingType.bindingIndex, type: bufferBindingType)
    }
}
