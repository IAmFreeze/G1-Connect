import Foundation
import UIKit
import CoreGraphics
import CoreImage

struct BitmapConverter {
    static func convertToBitmap(image: UIImage, width: Int = 136, height: Int = 136) -> Data? {
        // Resize image to target dimensions
        guard let resizedImage = resizeImage(image: image, targetSize: CGSize(width: width, height: height)) else {
            print("Failed to resize image")
            return nil
        }
        
        // Convert to grayscale
        guard let grayscaleImage = convertToGrayscale(image: resizedImage) else {
            print("Failed to convert to grayscale")
            return nil
        }
        
        // Convert to 1-bit bitmap
        guard let bitmapData = convertTo1BitBitmap(image: grayscaleImage) else {
            print("Failed to convert to 1-bit bitmap")
            return nil
        }
        
        return bitmapData
    }
    
    private static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private static func convertToGrayscale(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage")
            return nil
        }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else {
            print("Failed to create grayscale filter")
            return nil
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter.outputImage,
              let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("Failed to process grayscale filter")
            return nil
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    private static func convertTo1BitBitmap(image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage for 1-bit conversion")
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = (width + 7) / 8
        let bitsPerComponent = 1
        
        // Create bitmap context
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo.alphaInfoMask.rawValue & CGImageAlphaInfo.none.rawValue
        ) else {
            print("Failed to create bitmap context")
            return nil
        }
        
        // Draw image in context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Get bitmap data
        guard let bitmapData = context.data else {
            print("Failed to get bitmap data")
            return nil
        }
        
        // Create BMP header
        let fileHeaderSize = 14
        let infoHeaderSize = 40
        let headerSize = fileHeaderSize + infoHeaderSize
        let imageSize = bytesPerRow * height
        let fileSize = headerSize + imageSize + 8 // +8 for color table
        
        var bmpData = Data()
        bmpData.reserveCapacity(fileSize)
        
        // File header (14 bytes)
        bmpData.append(contentsOf: [0x42, 0x4D])                      // Signature 'BM'
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) }) // File size
        bmpData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])          // Reserved
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(headerSize + 8).littleEndian) { Array($0) }) // Offset to pixel data
        
        // Info header (40 bytes)
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(infoHeaderSize).littleEndian) { Array($0) }) // Info header size
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(width).littleEndian) { Array($0) })         // Width
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(height).littleEndian) { Array($0) })        // Height
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })             // Planes
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })             // Bits per pixel
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) })             // Compression
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(imageSize).littleEndian) { Array($0) })     // Image size
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(2835).littleEndian) { Array($0) })          // X pixels per meter
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(2835).littleEndian) { Array($0) })          // Y pixels per meter
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(2).littleEndian) { Array($0) })             // Colors in color table
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) })             // Important color count
        
        // Color table (8 bytes for 1-bit bitmap)
        bmpData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])          // Black
        bmpData.append(contentsOf: [0xFF, 0xFF, 0xFF, 0x00])          // White
        
        // Pixel data (needs to be flipped vertically for BMP format)
        let buffer = UnsafeBufferPointer(start: bitmapData.bindMemory(to: UInt8.self, capacity: imageSize), count: imageSize)
        for row in (0..<height).reversed() {
            let rowOffset = row * bytesPerRow
            for col in 0..<bytesPerRow {
                if rowOffset + col < buffer.count {
                    bmpData.append(buffer[rowOffset + col])
                } else {
                    bmpData.append(0x00) // Padding byte
                }
            }
        }
        
        return bmpData
    }
}
