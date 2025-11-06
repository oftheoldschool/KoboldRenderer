public enum KRRenderingMode: Hashable, CustomStringConvertible, CaseIterable {
    case forward
    case deferred

    public var description: String {
        return switch self {
        case .forward: "forward"
        case .deferred: "deferred"
        }
    }
}

public struct KRRendererSettings {
    public var renderingMode: KRRenderingMode
    public var transparencyEnabled: Bool
    public var bloomEnabled: Bool
    public var msaaEnabled: Bool
    public var msaaSampleCount: Int
    public var shadowsEnabled: Bool
    public var lightingEnabled: Bool
    public var flatShadingEnabled: Bool
    public var bloomGaussianBlurSigma: Float
    public var bloomThreshold: SIMD3<Float>
    public var bloomMultiplier: SIMD3<Float>
    public var outputImageScale: Float
    public var globalMaterial: String
    public var globalLightingColor: SIMD3<Float>
    public var cascadeFrustumDistances: [Float]
    public var clearColor: SIMD3<Float>
    public var shadowNormalBias: Float
    public var shadowBiasAngleFactor: Float
    public var shadowCascadeFactor: Float
    public var depthBias: Float
    public var depthSlopeScale: Float
    public var depthClamp: Float

    public init(
        renderingMode: KRRenderingMode = .forward,
        transparencyEnabled: Bool = true,
        bloomEnabled: Bool = true,
        msaaEnabled: Bool = true,
        msaaSampleCount: Int = 4,
        shadowsEnabled: Bool = true,
        lightingEnabled: Bool = true,
        flatShadingEnabled: Bool = false,
        bloomGaussianBlurSigma: Float = 4.0,
        bloomThreshold: SIMD3<Float> = SIMD3<Float>(0.8, 0.8, 0.8),
        bloomMultiplier: SIMD3<Float> = SIMD3<Float>(1.0, 1.0, 1.0),
        outputImageScale: Float = 1.0,
        globalMaterial: String = "none",
        globalLightingColor: SIMD3<Float>,
        cascadeFrustumDistances: [Float],
        clearColor: SIMD3<Float>,
        shadowNormalBias: Float = 0.0001,
        shadowBiasAngleFactor: Float = 0.2,
        shadowCascadeFactor: Float = 0.3,
        depthBias: Float = 1,
        depthSlopeScale: Float = 3,
        depthClamp: Float = 0.008
    ) {
        self.renderingMode = renderingMode
        self.transparencyEnabled = transparencyEnabled
        self.bloomEnabled = bloomEnabled
        self.msaaEnabled = msaaEnabled
        self.msaaSampleCount = msaaSampleCount
        self.shadowsEnabled = shadowsEnabled
        self.lightingEnabled = lightingEnabled
        self.flatShadingEnabled = flatShadingEnabled
        self.bloomGaussianBlurSigma = bloomGaussianBlurSigma
        self.bloomThreshold = bloomThreshold
        self.bloomMultiplier = bloomMultiplier
        self.outputImageScale = outputImageScale
        self.globalMaterial = globalMaterial
        self.globalLightingColor = globalLightingColor
        self.cascadeFrustumDistances = cascadeFrustumDistances
        self.clearColor = clearColor
        self.shadowNormalBias = shadowNormalBias
        self.shadowBiasAngleFactor = shadowBiasAngleFactor
        self.shadowCascadeFactor = shadowCascadeFactor
        self.depthBias = depthBias
        self.depthSlopeScale = depthSlopeScale
        self.depthClamp = depthClamp
    }

    func requiresReinit(previous: KRRendererSettings) -> Bool {
        return bloomEnabled != previous.bloomEnabled
        || msaaEnabled != previous.msaaEnabled
        || renderingMode != previous.renderingMode
        || cascadeFrustumDistances != previous.cascadeFrustumDistances
    }

    func requiresResize(previous: KRRendererSettings) -> Bool {
        return bloomEnabled != previous.bloomEnabled
        || msaaEnabled != previous.msaaEnabled
        || outputImageScale != previous.outputImageScale
        || renderingMode != previous.renderingMode
        || cascadeFrustumDistances != previous.cascadeFrustumDistances
    }
}
