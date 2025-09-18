import Metal

public struct AttachmentLayout {
    public let name: String
    public let colorAttachments: [ColorAttachment]
    public let depthAttachment: DepthAttachment?
}

public enum PixelFormat {
    case bgra8Unorm
    case rgba32Float
    case rgba16Float
    case r16Float
    case depth32
    case invalid

    func toMTLPixelFormat() -> MTLPixelFormat {
        return switch self {
        case .bgra8Unorm:
            .bgra8Unorm
        case .rgba32Float:
            .rgba32Float
        case .rgba16Float:
            .rgba16Float
        case .depth32:
            .depth32Float
        case .r16Float:
            .r16Float
        case .invalid:
            .invalid
        }
    }
}

public struct DepthAttachment {
    public let pixelFormat: PixelFormat

    public init(pixelFormat: PixelFormat) {
        self.pixelFormat = pixelFormat
    }
}

public struct ColorAttachment {
    public let pixelFormat: PixelFormat
    public let enableTransparency: Bool

    public init(
        description: String,
        pixelFormat: PixelFormat,
        enableTransparency: Bool = false
    ) {
        self.pixelFormat = pixelFormat
        self.enableTransparency = enableTransparency
    }

    func toMTLRenderPipelineColorAttachmentDescriptor() -> MTLRenderPipelineColorAttachmentDescriptor {
        let descriptor = MTLRenderPipelineColorAttachmentDescriptor()
        descriptor.pixelFormat = pixelFormat.toMTLPixelFormat()

        // bit of a hack. maybe these should be configurable
        if enableTransparency {
            if pixelFormat == .r16Float {
                // revealage texture
                descriptor.isBlendingEnabled = true
                descriptor.sourceRGBBlendFactor = .zero
                descriptor.destinationRGBBlendFactor = .oneMinusSourceColor
                descriptor.rgbBlendOperation = .add
            } else {
                // accumulation texture
                descriptor.isBlendingEnabled = true
                descriptor.sourceRGBBlendFactor = .one
                descriptor.destinationRGBBlendFactor = .one
                descriptor.rgbBlendOperation = .add
                descriptor.sourceAlphaBlendFactor = .one
                descriptor.destinationAlphaBlendFactor = .one
                descriptor.alphaBlendOperation = .add
            }
        }

        return descriptor
    }
}
