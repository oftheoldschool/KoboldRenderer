import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public struct KImageData {
    public let width: Int
    public let height: Int
    public let data: [UInt8]
}

extension CGImage {
    public func pixelsRGBA() -> (Int, Int, [UInt8]) {
        let width = self.width
        let height = self.height
        let componentCount = 4 
        let bytesPerRow = width * componentCount
        let dataSize = width * height * componentCount

        var pixelData = [UInt8](repeating: 0, count: dataSize)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return (0, 0, [])
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return (width, height, pixelData)
    }
}

public func loadImageData(data: Data) -> KImageData? {
    guard let dataProvider = CGDataProvider(data: data as CFData),
          let cgImage = CGImage(
            jpegDataProviderSource: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
          ) ?? CGImage(
            pngDataProviderSource: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
          ) else {
        // Fallback to ImageIO for other formats
        return loadImageDataWithImageIO(data: data)
    }

    let (width, height, pixelData) = cgImage.pixelsRGBA()

    return KImageData(
        width: width,
        height: height,
        data: pixelData
    )
}

private func loadImageDataWithImageIO(data: Data) -> KImageData? {
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        return nil
    }

    let (width, height, pixelData) = cgImage.pixelsRGBA()

    return KImageData(
        width: width,
        height: height,
        data: pixelData
    )
}
