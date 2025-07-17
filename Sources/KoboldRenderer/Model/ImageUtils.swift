import Foundation
import UIKit
import UniformTypeIdentifiers

public struct KImageData {
    public let width: Int
    public let height: Int
    public let data: [UInt8]
}

extension UIImage {
    public func pixelsRGBA() -> (Int, Int, [UInt8]) {
        guard let cgImage = self.cgImage else {
            return (0, 0, [])
        }
        let bitsPerComponent = cgImage.bitsPerComponent
        let bitsPerPixel = cgImage.bitsPerPixel
        let componentCount = bitsPerPixel / bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let dataSize = cgImage.width * cgImage.height * componentCount
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let bitmapInfo = cgImage.bitmapInfo
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        
        let _ = switch cgImage.alphaInfo {
        case .premultipliedLast: "premultipliedLast"
        case .alphaOnly: "alphaOnly"
        case .first: "first"
        case .last: "last"
        case .none: "none"
        case .noneSkipFirst: "noneSkipFirst"
        case .noneSkipLast: "noneSkipLast"
        case .premultipliedFirst: "premultipliedFirst"
        default: "unknown"
        }
        
        let context = CGContext(
            data: &pixelData,
            width: Int(cgImage.width),
            height: Int(cgImage.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue)
        context?.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return (cgImage.width, cgImage.height, pixelData)
    }
}

public func loadImageData(data: Data) -> KImageData {
    let uiImage = UIImage(data: data)!
    let (width, height, image) = uiImage.pixelsRGBA()
    
    return KImageData(
        width: width,
        height: height,
        data: image)
}
