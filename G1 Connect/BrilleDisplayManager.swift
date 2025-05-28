import Foundation
import UIKit
import SwiftUI

/// Position für die Anzeige auf der Brille
enum DisplayPosition {
    case characterBox
    case contextBox
    case fullDisplay
}

/// Manager für die Anzeige auf der G1-Brille
class BrilleDisplayManager {
    static let shared = BrilleDisplayManager()
    
    // Konstanten für das Layout
    let characterBoxWidth: Int = 160
    let characterBoxHeight: Int = 160
    let contextBoxWidth: Int = 480
    let contextBoxHeight: Int = 200
    let totalWidth: Int = 640
    let totalHeight: Int = 200
    
    // Maximale Textbreite und Schriftgröße für die Context Box
    let maxTextWidth: Int = 488
    let recommendedFontSize: Int = 21
    let linesPerScreen: Int = 5
    
    private init() {
        print("BrilleDisplayManager initialisiert")
    }
    
    /// Sendet ein Bild an die Character Box der Brille
    func sendCharacterImage(_ image: UIImage) {
        // Bild auf 160x160 skalieren
        let resizedImage = resizeImage(image, to: CGSize(width: characterBoxWidth, height: characterBoxHeight))
        
        // In 1-Bit BMP konvertieren
        guard let bmpData = BitmapConverter.convertToBitmap(image: resizedImage,
                                                           width: characterBoxWidth,
                                                           height: characterBoxHeight) else {
            print("Fehler beim Konvertieren des Character-Bildes")
            return
        }
        
        // An die Brille senden (linke Seite des Displays)
        BluetoothManager.shared.sendBMPDataToGlasses(bmpData, position: .characterBox)
    }
    
    /// Sendet Text an die Context Box der Brille
    func sendContextText(_ text: String) {
        // Text für die Context Box formatieren und senden
        BluetoothManager.shared.sendTextToGlasses(text, 
                                                maxWidth: maxTextWidth, 
                                                fontSize: recommendedFontSize, 
                                                linesPerScreen: linesPerScreen,
                                                position: .contextBox)
    }
    
    /// Aktualisiert die gesamte Brillenanzeige mit Character und Context
    func updateDisplay(characterImage: UIImage, contextText: String) {
        if BluetoothManager.shared.isConnected {
            // Character Box aktualisieren
            sendCharacterImage(characterImage)
            
            // Context Box aktualisieren
            sendContextText(contextText)
        } else {
            print("Keine Verbindung zur Brille")
        }
    }
    
    /// Erstellt ein kombiniertes Bild für das gesamte Display
    func createCombinedDisplayImage(characterImage: UIImage, contextText: String) -> UIImage? {
        // Neues Bild mit der Gesamtgröße erstellen
        UIGraphicsBeginImageContextWithOptions(CGSize(width: totalWidth, height: totalHeight), false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Character Box zeichnen
        let resizedCharacterImage = resizeImage(characterImage, to: CGSize(width: characterBoxWidth, height: characterBoxHeight))
        resizedCharacterImage.draw(in: CGRect(x: 0, y: 0, width: characterBoxWidth, height: characterBoxHeight))
        
        // Context Box mit Text zeichnen
        let contextRect = CGRect(x: characterBoxWidth, y: 0, width: contextBoxWidth, height: contextBoxHeight)
        UIColor.black.setFill()
        UIRectFill(contextRect)
        
        // Text in Context Box zeichnen
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: CGFloat(recommendedFontSize)),
            .foregroundColor: UIColor.green,
            .paragraphStyle: paragraphStyle
        ]
        
        let textRect = CGRect(x: characterBoxWidth + 10, y: 10, width: contextBoxWidth - 20, height: contextBoxHeight - 20)
        contextText.draw(in: textRect, withAttributes: textAttributes)
        
        // Fertiges Bild zurückgeben
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Hilfsmethoden
    
    /// Skaliert ein Bild auf die angegebene Größe
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Erweiterungen für BluetoothManager

extension BluetoothManager {
    /// Sendet BMP-Daten an die Brille
    func sendBMPDataToGlasses(_ bmpData: Data, position: DisplayPosition) {
        // Daten in 194-Byte-Pakete aufteilen
        let packetSize = 194
        let totalPackets = (bmpData.count + packetSize - 1) / packetSize
        
        for i in 0..<totalPackets {
            let start = i * packetSize
            let end = min(start + packetSize, bmpData.count)
            let packetData = bmpData.subdata(in: start..<end)
            
            // Paket mit Kommando und Index versehen
            var commandData = Data([0x15, UInt8(i & 0xff)])
            
            // Für das erste Paket die Speicheradresse hinzufügen
            if i == 0 {
                commandData.append(contentsOf: [0x00, 0x1c, 0x00, 0x00])
            }
            
            // Paketdaten hinzufügen
            commandData.append(packetData)
            
            // An beide Seiten der Brille senden
            writeData(writeData: commandData, lr: "L")
            writeData(writeData: commandData, lr: "R")
        }
        
        // Paketende-Kommando senden
        let endCommand = Data([0x20, 0x0d, 0x0e])
        writeData(writeData: endCommand, lr: "L")
        writeData(writeData: endCommand, lr: "R")
        
        // CRC-Prüfung senden (vereinfachte Implementierung)
        let crcCommand = Data([0x16, 0x00])
        writeData(writeData: crcCommand, lr: "L")
        writeData(writeData: crcCommand, lr: "R")
    }
    
    /// Sendet Text an die Brille
    func sendTextToGlasses(_ text: String, maxWidth: Int, fontSize: Int, linesPerScreen: Int, position: DisplayPosition) {
        // Text in Zeilen aufteilen
        let lines = splitTextIntoLines(text, maxWidth: maxWidth, fontSize: fontSize)
        
        // Zeilen in Bildschirme aufteilen
        let screens = splitLinesIntoScreens(lines, linesPerScreen: linesPerScreen)
        
        // Bildschirme nacheinander senden
        for (i, screen) in screens.enumerated() {
            sendScreenToGlasses(screen, currentPage: i, totalPages: screens.count)
        }
    }
    
    /// Teilt Text in Zeilen auf, die auf das Display passen
    func splitTextIntoLines(_ text: String, maxWidth: Int, fontSize: Int) -> [String] {
        // Vereinfachte Implementierung: Teilt den Text nach Satzzeichen und Wortgrenzen auf
        var lines: [String] = []
        let words = text.components(separatedBy: " ")
        
        var currentLine = ""
        for word in words {
            let testLine = currentLine.isEmpty ? word : "\(currentLine) \(word)"
            
            // Einfache Schätzung der Textbreite (in einer realen Implementierung würde man die tatsächliche Textbreite berechnen)
            let estimatedWidth = testLine.count * fontSize / 2
            
            if estimatedWidth <= maxWidth {
                currentLine = testLine
            } else {
                lines.append(currentLine)
                currentLine = word
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines
    }
    
    /// Teilt Zeilen in Bildschirme auf
    func splitLinesIntoScreens(_ lines: [String], linesPerScreen: Int) -> [[String]] {
        var screens: [[String]] = []
        var currentScreen: [String] = []
        
        for line in lines {
            if currentScreen.count < linesPerScreen {
                currentScreen.append(line)
            } else {
                screens.append(currentScreen)
                currentScreen = [line]
            }
        }
        
        if !currentScreen.isEmpty {
            screens.append(currentScreen)
        }
        
        return screens
    }
    
    /// Sendet einen Bildschirm an die Brille
    private func sendScreenToGlasses(_ screen: [String], currentPage: Int, totalPages: Int) {
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
        
        // Kurze Pause zwischen den Bildschirmen
        Thread.sleep(forTimeInterval: 0.5)
    }
}
