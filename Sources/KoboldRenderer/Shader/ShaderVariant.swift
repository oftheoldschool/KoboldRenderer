enum ComputeFunctionVariant: Hashable {
    case color
    case colorPlusBloom

    var isBloom: Bool {
        return self == .colorPlusBloom
    }
}

enum VertexFunctionVariant: CaseIterable, CustomStringConvertible {
    case single
    case singleShadow
    case instanced
    case instancedShadow
    case singleAnimated
    case singleAnimatedShadow
    case instancedAnimated
    case instancedAnimatedShadow

    var description: String {
        return switch self {
        case .single:
            "single"
        case .singleShadow:
            "singleShadow"
        case .instanced:
            "instanced"
        case .instancedShadow:
            "instancedShadow"
        case .singleAnimated:
            "singleAnimated"
        case .singleAnimatedShadow:
            "singleAnimatedShadow"
        case .instancedAnimated:
            "instancedAnimated"
        case .instancedAnimatedShadow:
            "instancedAnimatedShadow"
        }
    }

    var isShadow: Bool {
        return self == .singleShadow || self == .instancedShadow || self == .singleAnimatedShadow || self == .instancedAnimatedShadow
    }

    var isInstanced: Bool {
        return self == .instanced || self == .instancedShadow || self == .instancedAnimated || self == .instancedAnimatedShadow
    }

    var isAnimated: Bool {
        return self == .singleAnimated || self == .singleAnimatedShadow || self == .instancedAnimated || self == .instancedAnimatedShadow
    }
}

public enum FragmentFunctionVariant: CaseIterable, CustomStringConvertible {
    case color
    case colorAlpha
    case colorPlusBrightness
    case colorAlphaPlusBrightness
    case gbuffer
    case instancedColor
    case instancedColorAlpha
    case instancedColorPlusBrightness
    case instancedColorAlphaPlusBrightness
    case instancedGBuffer

    public var description: String {
        return switch self {
        case .color:
            "color"
        case .colorAlpha:
            "colorAlpha"
        case .colorPlusBrightness:
            "colorPlusBrightness"
        case .colorAlphaPlusBrightness:
            "colorAlphaPlusBrightness"
        case .gbuffer:
            "gbuffer"
        case .instancedColor:
            "instancedColor"
        case .instancedColorAlpha:
            "instancedColorAlpha"
        case .instancedColorPlusBrightness:
            "instancedColorPlusBrightness"
        case .instancedColorAlphaPlusBrightness:
            "instancedColorAlphaPlusBrightness"
        case .instancedGBuffer:
            "instancedGBuffer"
        }
    }

    public var isBloom: Bool {
        return [
            .colorPlusBrightness,
            .colorAlphaPlusBrightness,
            .instancedColorPlusBrightness,
            .instancedColorAlphaPlusBrightness,
        ].contains(self)
    }

    public var isInstanced: Bool {
        return [
            .instancedColor,
            .instancedColorAlpha,
            .instancedColorPlusBrightness,
            .instancedColorAlphaPlusBrightness,
            .instancedGBuffer,
        ].contains(self)
    }

    public var isTransparency: Bool {
        return [
            .colorAlpha,
            .colorAlphaPlusBrightness,
            .instancedColorAlpha,
            .instancedColorAlphaPlusBrightness,
        ].contains(self)
    }

    public var isGBuffer: Bool {
        return self == .gbuffer || self == .instancedGBuffer
    }
}
