import Metal

extension MTLClearColor {
    static var black: MTLClearColor {
        return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    }

    static var white: MTLClearColor {
        return MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
    }

    static var grey: MTLClearColor {
        return MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    }

    static var red: MTLClearColor {
        return MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
    }

    static var green: MTLClearColor {
        return MTLClearColor(red: 0, green: 1, blue: 0, alpha: 1)
    }

    static var blue: MTLClearColor {
        return MTLClearColor(red: 0, green: 0, blue: 1, alpha: 1)
    }

    static var cyan: MTLClearColor {
        return MTLClearColor(red: 0, green: 1, blue: 1, alpha: 1)
    }

    static var magenta: MTLClearColor {
        return MTLClearColor(red: 1, green: 0, blue: 1, alpha: 1)
    }

    static var yellow: MTLClearColor {
        return MTLClearColor(red: 1, green: 1, blue: 0, alpha: 1)
    }

    init(_ color: SIMD3<Float>) {
        self.init(
            red: Double(color.x),
            green: Double(color.y),
            blue: Double(color.z),
            alpha: 1)
    }

    init(_ color: SIMD4<Float>) {
        self.init(
            red: Double(color.x),
            green: Double(color.y),
            blue: Double(color.z),
            alpha: Double(color.w))
    }
}
