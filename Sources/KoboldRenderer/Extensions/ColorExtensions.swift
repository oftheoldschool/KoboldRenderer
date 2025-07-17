import SwiftUI
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

#if canImport(UIKit)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &o)
#elseif canImport(AppKit)
        NSColor(self).getRed(&r, green: &g, blue: &b, alpha: &o)
#endif

        return (Double(r), Double(g), Double(b), Double(o))
    }
}
