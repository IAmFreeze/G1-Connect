import Foundation
import UIKit
import SwiftUI

/// G1 Display Manager using official protocol specifications
class G1DisplayManager {
    static let shared = G1DisplayManager()
    
    private init() {
        print("G1DisplayManager initialized with official protocol")
    }
    
    // MARK: - Public Methods
    
    /// Sends a 1-bit BMP image to G1 using official protocol
    /// - Parameters:
    ///   - image: UIImage to convert and send
    ///   - completion: Completion handler with success status
    func sendImageToG1(_ image: UIImage, completion: @escaping (Bool) -> Void = { _ in }) {
        guard BluetoothManager.shared.isConnected else {
            print("Error: No G1 connection")
            completion(false)
            return
        }
        
        // Convert to official G1 format: 1-bit BMP 576x136
        guard let bmpData = convertToG1BMP(image: image) else {
            print("Error: Failed to convert image to G1 BMP format")
            completion(false)
            return
        }
        
        // Send using BluetoothManager
        BluetoothManager.shared.sendImageToG1(bmpData)
        completion(true)
    }
    
    /// Sends text to G1 using official text protocol
    /// - Parameters:
    ///   - text: Text to display
    ///   - completion: Completion handler with success status
    func sendTextToG1(_ text: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard BluetoothManager.shared.isConnected else {
            print("Error: No G1 connection")
            completion(false)
            return
        }
        
        BluetoothManager.shared.sendTextToG1(text)
        completion(true)
    }
    
    /// Updates G1 display with Lily's current state
    /// - Parameters:
    ///   - emotion: Current Lily emotion
    ///   - message: Current Lily message
    func updateLilyDisplay(emotion: LilyEmotion, message: String) {
        // Get emotion image
        if let emotionImage = getEmotionImage(for: emotion) {
            sendImageToG1(emotionImage)
        }
        
        // Send message text
        let formattedMessage = formatLilyMessage(message, emotion: emotion)
        sendTextToG1(formattedMessage)
    }
    
    /// Displays Even AI status on G1
    /// - Parameter status: Current Even AI status
    func displayEvenAIStatus(_ status: EvenAIStatus) {
        let statusText: String
        
        switch status {
        case .activated:
            statusText = "🎤 Even AI aktiviert\nSprich jetzt..."
        case .processing:
            statusText = "🤔 Verarbeite deine Anfrage..."
        case .responding:
            statusText = "💬 Lily antwortet..."
        case .error(let message):
            statusText = "❌ Fehler: \(message)"
        case .complete:
            statusText = "✅ Fertig"
        }
        
        sendTextToG1(statusText)
    }
    
    // MARK: - Image Conversion
    
    private func convertToG1BMP(image: UIImage) -> Data? {
        // Resize to G1 specifications
        let resizedImage = resizeImage(image, to: CGSize(
            width: Constants.G1Display.imageWidth,
            height: Constants.G1Display.imageHeight
        ))
        
        // Convert to grayscale
        let grayscaleImage = convertToGrayscale(resizedImage)
        
        // Convert to 1-bit BMP
        return convertTo1BitBMP(grayscaleImage)
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func convertToGrayscale(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let context = CIContext(options: nil)
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else { return image }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter.outputImage,
              let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    private func convertTo1BitBMP(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = Constants.G1Display.imageWidth
        let height = Constants.G1Display.imageHeight
        let bytesPerRow = (width + 7) / 8 // 1 bit per pixel, rounded up to nearest byte
        let bitsPerComponent = 1
        
        // Create bitmap context for 1-bit grayscale
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo().rawValue
        ) else {
            print("Failed to create 1-bit bitmap context")
            return nil
        }
        
        // Draw image in context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Get bitmap data
        guard let bitmapData = context.data else {
            print("Failed to get bitmap data")
            return nil
        }
        
        // Create BMP file structure
        return createBMPFile(
            bitmapData: bitmapData,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow
        )
    }
    
    private func createBMPFile(bitmapData: UnsafeMutableRawPointer, width: Int, height: Int, bytesPerRow: Int) -> Data {
        var bmpData = Data()
        
        // BMP file header (14 bytes)
        let fileHeaderSize = 14
        let infoHeaderSize = 40
        let colorTableSize = 8 // 2 colors × 4 bytes each
        let dataOffset = fileHeaderSize + infoHeaderSize + colorTableSize
        let imageSize = bytesPerRow * height
        let fileSize = dataOffset + imageSize
        
        // File header
        bmpData.append(contentsOf: [0x42, 0x4D]) // "BM" signature
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        bmpData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Reserved
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(dataOffset).littleEndian) { Array($0) })
        
        // Info header (40 bytes)
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(infoHeaderSize).littleEndian) { Array($0) })
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(width).littleEndian) { Array($0) })
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(height).littleEndian) { Array($0) })
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // Planes
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // Bits per pixel
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) }) // Compression
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(imageSize).littleEndian) { Array($0) })
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(2835).littleEndian) { Array($0) }) // X pixels per meter
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(2835).littleEndian) { Array($0) }) // Y pixels per meter
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(2).littleEndian) { Array($0) }) // Colors used
        bmpData.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) }) // Important colors
        
        // Color table (8 bytes for 1-bit)
        bmpData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Black
        bmpData.append(contentsOf: [0xFF, 0xFF, 0xFF, 0x00]) // White
        
        // Bitmap data (bottom-up format for BMP)
        let buffer = bitmapData.bindMemory(to: UInt8.self, capacity: imageSize)
        for row in (0..<height).reversed() {
            let rowOffset = row * bytesPerRow
            for col in 0..<bytesPerRow {
                if rowOffset + col < imageSize {
                    bmpData.append(buffer[rowOffset + col])
                } else {
                    bmpData.append(0x00)
                }
            }
        }
        
        return bmpData
    }
    
    // MARK: - Text Formatting
    
    private func formatLilyMessage(_ message: String, emotion: LilyEmotion) -> String {
        let emotionEmoji = getEmotionEmoji(for: emotion)
        return "\(emotionEmoji) Lily\n\(message)"
    }
    
    private func getEmotionEmoji(for emotion: LilyEmotion) -> String {
        switch emotion {
        case .happy: return "😊"
        case .cheerful: return "😄"
        case .thoughtful: return "🤔"
        case .serious: return "😐"
        case .surprised: return "😮"
        case .questioning: return "🤨"
        }
    }
    
    private func getEmotionImage(for emotion: LilyEmotion) -> UIImage? {
        // Try to load emotion-specific image
        if let image = UIImage(named: emotion.imageName) {
            return image
        }
        
        // Fallback to system image with emotion color
        let systemImageName: String
        let tintColor: UIColor
        
        switch emotion {
        case .happy:
            systemImageName = "face.smiling"
            tintColor = .systemYellow
        case .cheerful:
            systemImageName = "face.smiling.inverse"
            tintColor = .systemOrange
        case .thoughtful:
            systemImageName = "brain.head.profile"
            tintColor = .systemBlue
        case .serious:
            systemImageName = "face.dashed"
            tintColor = .systemGray
        case .surprised:
            systemImageName = "exclamationmark.circle"
            tintColor = .systemRed
        case .questioning:
            systemImageName = "questionmark.circle"
            tintColor = .systemPurple
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 100, weight: .regular, scale: .large)
        let image = UIImage(systemName: systemImageName, withConfiguration: config)
        
        return image?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
    }
    
    // MARK: - Utility Methods
    
    /// Creates a test pattern for G1 display testing
    func sendTestPattern() {
        guard BluetoothManager.shared.isConnected else { return }
        
        // Create test pattern image
        let testImage = createTestPatternImage()
        sendImageToG1(testImage)
        
        // Send test text
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let currentTime = formatter.string(from: Date())
        sendTextToG1("G1 Display Test\nVerbindung erfolgreich!\n\nTime: \(currentTime)")
    }
    
    private func createTestPatternImage() -> UIImage {
        let size = CGSize(width: Constants.G1Display.imageWidth, height: Constants.G1Display.imageHeight)
        
        return UIGraphicsImageRenderer(size: size).image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.black.setFill()
            context.fill(rect)
            
            // Grid pattern
            UIColor.white.setStroke()
            context.cgContext.setLineWidth(1.0)
            
            let gridSize = 20
            for x in stride(from: 0, to: Int(size.width), by: gridSize) {
                context.cgContext.move(to: CGPoint(x: CGFloat(x), y: 0.0)) // Ensure y is CGFloat
                context.cgContext.addLine(to: CGPoint(x: CGFloat(x), y: size.height))
                context.cgContext.strokePath()
            }
            
            for y in stride(from: 0, to: Int(size.height), by: gridSize) {
                context.cgContext.move(to: CGPoint(x: 0.0, y: CGFloat(y))) // Ensure x is CGFloat
                context.cgContext.addLine(to: CGPoint(x: size.width, y: CGFloat(y)))
                context.cgContext.strokePath()
            }
            
            // Center circle
            let centerRect = CGRect(
                x: size.width/2 - 30,
                y: size.height/2 - 30,
                width: 60,
                height: 60
            )
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: centerRect)
        }
    }
}

// MARK: - Even AI Status

enum EvenAIStatus {
    case activated
    case processing
    case responding
    case error(String)
    case complete
}
