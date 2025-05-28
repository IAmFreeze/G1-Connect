import Foundation
import UIKit

/// Optimierter BitmapConverter für die G1-Brille
class OptimizedBitmapConverter {
    
    /// Konvertiert ein Bild in das 1-Bit-BMP-Format für die G1-Brille
    static func convertToBrilleFormat(image: UIImage, width: Int, height: Int) -> Data? {
        // Bild auf die gewünschte Größe skalieren
        let resizedImage = resizeImage(image, to: CGSize(width: width, height: height))
        
        // In Schwarz-Weiß konvertieren
        let bwImage = convertToBlackAndWhite(resizedImage)
        
        // In 1-Bit-BMP konvertieren
        return convertTo1BitBMP(bwImage, width: width, height: height)
    }
    
    /// Erstellt ein kombiniertes Bild für das gesamte Display (640x200)
    static func createCombinedDisplayImage(characterImage: UIImage, contextText: String) -> Data? {
        // Neues Bild mit der Gesamtgröße erstellen
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 640, height: 200), false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Character Box zeichnen (160x160)
        let resizedCharacterImage = resizeImage(characterImage, to: CGSize(width: 160, height: 160))
        resizedCharacterImage.draw(in: CGRect(x: 0, y: 0, width: 160, height: 160))
        
        // Context Box mit Text zeichnen (480x200)
        let contextRect = CGRect(x: 160, y: 0, width: 480, height: 200)
        UIColor.black.setFill()
        UIRectFill(contextRect)
        
        // Text in Context Box zeichnen
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21),
            .foregroundColor: UIColor.green,
            .paragraphStyle: paragraphStyle
        ]
        
        let textRect = CGRect(x: 170, y: 10, width: 460, height: 180)
        contextText.draw(in: textRect, withAttributes: textAttributes)
        
        // Fertiges Bild holen
        guard let combinedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        // In 1-Bit-BMP konvertieren
        return convertTo1BitBMP(combinedImage, width: 640, height: 200)
    }
    
    /// Optimierte Methode zur Konvertierung von Text in ein BMP-Bild für die Context Box
    static func convertTextToBMP(text: String, width: Int = 480, height: Int = 200, fontSize: Int = 21) -> Data? {
        // Neues Bild mit der Größe der Context Box erstellen
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Hintergrund zeichnen
        UIColor.black.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Text zeichnen
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: CGFloat(fontSize)),
            .foregroundColor: UIColor.green,
            .paragraphStyle: paragraphStyle
        ]
        
        let textRect = CGRect(x: 10, y: 10, width: width - 20, height: height - 20)
        text.draw(in: textRect, withAttributes: textAttributes)
        
        // Fertiges Bild holen
        guard let textImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        // In 1-Bit-BMP konvertieren
        return convertTo1BitBMP(textImage, width: width, height: height)
    }
    
    // MARK: - Hilfsmethoden
    
    /// Skaliert ein Bild auf die angegebene Größe
    private static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Konvertiert ein Bild in Schwarz-Weiß
    private static func convertToBlackAndWhite(_ image: UIImage) -> UIImage {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectMono") else { return image }
        currentFilter.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        
        guard let output = currentFilter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Konvertiert ein Bild in das 1-Bit-BMP-Format
    private static func convertTo1BitBMP(_ image: UIImage, width: Int, height: Int) -> Data? {
        // Bild in Bitmap-Kontext zeichnen
        guard let cgImage = image.cgImage else { return nil }
        
        // Berechnung der Bytes pro Zeile (muss ein Vielfaches von 4 sein)
        let bytesPerRow = ((width + 31) / 32) * 4
        let bitsPerPixel = 1
        let bitsPerComponent = 1
        
        // Bitmap-Kontext erstellen
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo.byteOrderDefault.rawValue
        ) else { return nil }
        
        // Bild in den Kontext zeichnen
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Bitmap-Daten holen
        guard let bitmapData = context.data else { return nil }
        
        // BMP-Header erstellen
        var bmpData = Data()
        
        // BMP-Dateiheader (14 Bytes)
        let fileHeaderSize = 14
        let infoHeaderSize = 40
        let dataOffset = fileHeaderSize + infoHeaderSize
        let fileSize = dataOffset + bytesPerRow * height
        
        // "BM" Signatur
        bmpData.append(contentsOf: [0x42, 0x4D])
        
        // Dateigröße (4 Bytes)
        bmpData.append(UInt8(fileSize & 0xFF))
        bmpData.append(UInt8((fileSize >> 8) & 0xFF))
        bmpData.append(UInt8((fileSize >> 16) & 0xFF))
        bmpData.append(UInt8((fileSize >> 24) & 0xFF))
        
        // Reserviert (4 Bytes)
        bmpData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        // Daten-Offset (4 Bytes)
        bmpData.append(UInt8(dataOffset & 0xFF))
        bmpData.append(UInt8((dataOffset >> 8) & 0xFF))
        bmpData.append(UInt8((dataOffset >> 16) & 0xFF))
        bmpData.append(UInt8((dataOffset >> 24) & 0xFF))
        
        // BMP-Infoheader (40 Bytes)
        
        // Header-Größe (4 Bytes)
        bmpData.append(UInt8(infoHeaderSize & 0xFF))
        bmpData.append(UInt8((infoHeaderSize >> 8) & 0xFF))
        bmpData.append(UInt8((infoHeaderSize >> 16) & 0xFF))
        bmpData.append(UInt8((infoHeaderSize >> 24) & 0xFF))
        
        // Bildbreite (4 Bytes)
        bmpData.append(UInt8(width & 0xFF))
        bmpData.append(UInt8((width >> 8) & 0xFF))
        bmpData.append(UInt8((width >> 16) & 0xFF))
        bmpData.append(UInt8((width >> 24) & 0xFF))
        
        // Bildhöhe (4 Bytes)
        bmpData.append(UInt8(height & 0xFF))
        bmpData.append(UInt8((height >> 8) & 0xFF))
        bmpData.append(UInt8((height >> 16) & 0xFF))
        bmpData.append(UInt8((height >> 24) & 0xFF))
        
        // Anzahl der Farbebenen (2 Bytes)
        bmpData.append(0x01)
        bmpData.append(0x00)
        
        // Bits pro Pixel (2 Bytes)
        bmpData.append(UInt8(bitsPerPixel))
        bmpData.append(0x00)
        
        // Kompression (4 Bytes) - keine Kompression
        bmpData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        // Bildgröße (4 Bytes)
        let imageSize = bytesPerRow * height
        bmpData.append(UInt8(imageSize & 0xFF))
        bmpData.append(UInt8((imageSize >> 8) & 0xFF))
        bmpData.append(UInt8((imageSize >> 16) & 0xFF))
        bmpData.append(UInt8((imageSize >> 24) & 0xFF))
        
        // Horizontale Auflösung (4 Bytes) - 72 DPI
        bmpData.append(contentsOf: [0x13, 0x0B, 0x00, 0x00])
        
        // Vertikale Auflösung (4 Bytes) - 72 DPI
        bmpData.append(contentsOf: [0x13, 0x0B, 0x00, 0x00])
        
        // Anzahl der Farben in der Palette (4 Bytes) - 2 Farben
        bmpData.append(contentsOf: [0x02, 0x00, 0x00, 0x00])
        
        // Anzahl der wichtigen Farben (4 Bytes) - alle wichtig
        bmpData.append(contentsOf: [0x02, 0x00, 0x00, 0x00])
        
        // Farbpalette (8 Bytes für 2 Farben)
        // Schwarz
        bmpData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        // Weiß
        bmpData.append(contentsOf: [0xFF, 0xFF, 0xFF, 0x00])
        
        // Bitmap-Daten hinzufügen (von unten nach oben)
        let bitmapDataPointer = bitmapData.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)
        for y in (0..<height).reversed() {
            let rowOffset = y * bytesPerRow
            for x in 0..<bytesPerRow {
                bmpData.append(bitmapDataPointer[rowOffset + x])
            }
        }
        
        return bmpData
    }
}

// Erweiterung des BluetoothManager für optimierte Datenübertragung
extension BluetoothManager {
    
    /// Optimierte Methode zum Senden von BMP-Daten an die Brille
    func sendOptimizedBMPDataToGlasses(_ bmpData: Data, position: DisplayPosition) {
        // Daten in 194-Byte-Pakete aufteilen
        let packetSize = 194
        let totalPackets = (bmpData.count + packetSize - 1) / packetSize
        
        // Speicheradresse basierend auf der Position
        var memoryAddress: [UInt8] = [0x00, 0x1c, 0x00, 0x00]
        
        // Pakete senden
        for i in 0..<totalPackets {
            let start = i * packetSize
            let end = min(start + packetSize, bmpData.count)
            let packetData = bmpData.subdata(in: start..<end)
            
            // Paket mit Kommando und Index versehen
            var commandData = Data([0x15, UInt8(i & 0xff)])
            
            // Für das erste Paket die Speicheradresse hinzufügen
            if i == 0 {
                commandData.append(contentsOf: memoryAddress)
            }
            
            // Paketdaten hinzufügen
            commandData.append(packetData)
            
            // An beide Seiten der Brille senden
            writeData(writeData: commandData, lr: "L")
            writeData(writeData: commandData, lr: "R")
            
            // Kurze Pause zwischen den Paketen
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        // Paketende-Kommando senden
        let endCommand = Data([0x20, 0x0d, 0x0e])
        writeData(writeData: endCommand, lr: "L")
        writeData(writeData: endCommand, lr: "R")
        
        // CRC-Prüfung senden
        let crcCommand = Data([0x16, 0x00])
        writeData(writeData: crcCommand, lr: "L")
        writeData(writeData: crcCommand, lr: "R")
    }
    
    /// Optimierte Methode zum Senden von Text an die Brille
    func sendOptimizedTextToGlasses(_ text: String, maxWidth: Int = 488, fontSize: Int = 21, linesPerScreen: Int = 5) {
        // Text in Zeilen aufteilen
        let lines = splitTextIntoLines(text, maxWidth: maxWidth, fontSize: fontSize)
        
        // Zeilen in Bildschirme aufteilen
        let screens = splitLinesIntoScreens(lines, linesPerScreen: linesPerScreen)
        
        // Bildschirme nacheinander senden
        for (i, screen) in screens.enumerated() {
            sendScreenToGlassesOptimized(screen, currentPage: i, totalPages: screens.count)
            
            // Kurze Pause zwischen den Bildschirmen
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    /// Optimierte Methode zum Senden eines Bildschirms an die Brille
    private func sendScreenToGlassesOptimized(_ screen: [String], currentPage: Int, totalPages: Int) {
        // Text für den Bildschirm zusammensetzen
        let screenText = screen.joined(separator: "\n")
        
        // Daten für das 0x4E-Kommando vorbereiten
        var commandData = Data([0x4E])
        
        // Sequenznummer (einfach den aktuellen Seitenindex verwenden)
        commandData.append(UInt8(currentPage & 0xff))
        
        // Gesamtpaketanzahl (1, da wir pro Bildschirm nur ein Paket senden)
        commandData.append(UInt8(1))
        
        // Aktuelles Paket (0, da es das einzige Paket ist)
        commandData.append(UInt8(0))
        
        // Bildschirmstatus (0x31: Neuer Inhalt + Even AI anzeigen)
        commandData.append(UInt8(0x31))
        
        // Neue Zeichenposition (0, da wir von vorne beginnen)
        commandData.append(UInt8(0))
        commandData.append(UInt8(0))
        
        // Aktuelle Seitennummer
        commandData.append(UInt8(currentPage))
        
        // Maximale Seitennummer
        commandData.append(UInt8(totalPages))
        
        // Text als Daten hinzufügen
        if let textData = screenText.data(using: .utf8) {
            commandData.append(textData)
        }
        
        // An beide Seiten der Brille senden
        writeData(writeData: commandData, lr: "L")
        writeData(writeData: commandData, lr: "R")
    }
}
