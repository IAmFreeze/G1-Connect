import Foundation
import SwiftUI

struct Constants {
    // Colors - SwiftUI
    static let backgroundColor = Color(red: 0.07, green: 0.07, blue: 0.07) // #121212
    static let secondaryBackgroundColor = Color(red: 0.12, green: 0.12, blue: 0.12) // #1E1E1E
    static let primaryColor = Color(red: 0.54, green: 0.17, blue: 0.89) // #8A2BE2 (lila)
    static let textColor = Color.white
    static let secondaryTextColor = Color(red: 0.67, green: 0.67, blue: 0.67) // #AAAAAA
    static let successColor = Color(red: 0.3, green: 0.69, blue: 0.31) // #4CAF50
    static let warningColor = Color(red: 1.0, green: 0.76, blue: 0.03) // #FFC107
    static let errorColor = Color(red: 0.96, green: 0.26, blue: 0.21) // #F44336
    
    // Colors - UIKit (for compatibility)
    static let backgroundColorUIKit = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)
    static let secondaryBackgroundColorUIKit = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
    static let primaryColorUIKit = UIColor(red: 0.54, green: 0.17, blue: 0.89, alpha: 1.0)
    
    // MARK: - G1 Official Protocol Commands
    struct G1Commands {
        // TouchBar Commands (from glasses to app)
        static let dashboardControl: UInt8 = 0xF5
        static let evenAIStart: [UInt8] = [0xF5, 0x17]      // Long press left TouchBar
        static let evenAIStop: [UInt8] = [0xF5, 0x24]       // Release TouchBar
        static let exitToDashboard: [UInt8] = [0xF5, 0x00]  // Exit features
        static let pageUp: [UInt8] = [0xF5, 0x01]           // Left TouchBar tap
        static let pageDown: [UInt8] = [0xF5, 0x01]         // Right TouchBar tap
        static let silentModeToggle: [UInt8] = [0xF5, 0x04] // Toggle silent mode
        
        // Microphone Commands (app to glasses)
        static let microphoneCommand: UInt8 = 0x0E
        static let microphoneEnable: [UInt8] = [0x0E, 0x01]
        static let microphoneDisable: [UInt8] = [0x0E, 0x00]
        
        // Audio Stream Commands (glasses to app)
        static let audioStream: UInt8 = 0xF1
        
        // Text Display Commands (app to glasses)
        static let textDisplay: UInt8 = 0x4E
        
        // Image Display Commands (app to glasses)
        static let imagePacket: UInt8 = 0x15
        static let imageEnd: [UInt8] = [0x20, 0x0d, 0x0e]
        static let imageCRC: UInt8 = 0x16

        // Connection maintenance and exit
        static let heartbeat: UInt8 = 0x25
        static let exitFeature: UInt8 = 0x18
    }
    
    // MARK: - G1 Display Specifications (Official)
    struct G1Display {
        // Image specifications
        static let imageWidth = 576
        static let imageHeight = 136
        static let imageBitsPerPixel = 1 // 1-bit BMP
        static let imagePacketSize = 194
        static let imageStorageAddress: [UInt8] = [0x00, 0x1c, 0x00, 0x00]
        
        // Text specifications
        static let maxTextWidth = 488
        static let recommendedFontSize = 21
        static let linesPerScreen = 5
        
        // Screen status codes
        static let displayNewContent: UInt8 = 0x01
        static let evenAIDisplaying: UInt8 = 0x30
        static let evenAIComplete: UInt8 = 0x40
        static let evenAIManual: UInt8 = 0x50
        static let evenAINetworkError: UInt8 = 0x60
        static let textShow: UInt8 = 0x70
        
        // Combined status codes
        static let newContentEvenAI: UInt8 = 0x31 // 0x01 | 0x30
        static let newContentTextShow: UInt8 = 0x71 // 0x01 | 0x70
    }
    
    // MARK: - G1 Audio Specifications
    struct G1Audio {
        static let format = "LC3" // Low Complexity Communication Codec
        static let maxRecordingDuration: TimeInterval = 30.0
        static let sampleRate: Double = 16000.0
        static let channels = 1
        static let frameSize = 240 // bytes per LC3 frame
    }
    
    // MARK: - G1 Response Codes
    struct G1Response {
        static let microphoneSuccess: UInt8 = 0xC9
        static let microphoneFailure: UInt8 = 0xCA
    }
    
    // Wake Word
    static let wakeWord = "Hey, Lily"
    
    // App Name
    static let appName = "G1 Connect"
    
    // Lily Emotions
    static let emotions: [LilyEmotion: String] = [
        .happy: "lily_happy",
        .cheerful: "lily_cheerful",
        .thoughtful: "lily_thoughtful",
        .serious: "lily_serious",
        .surprised: "lily_surprised",
        .questioning: "lily_questioning"
    ]
    
    // Standard Responses
    static let standardResponses: [String: String] = [
        "greeting": "Hallo! Ich bin Lily, deine persönliche Assistentin. Wie kann ich dir helfen?",
        "weather": "Das aktuelle Wetter ist sonnig mit 22°C. Ein perfekter Tag!",
        "time": "Es ist jetzt 14:30 Uhr.",
        "unknown": "Entschuldige, ich verstehe deine Anfrage nicht. Kannst du es anders formulieren?",
        "timer": "Timer für 5 Minuten gesetzt. Ich werde dich benachrichtigen, wenn die Zeit abgelaufen ist.",
        "reminder": "Ich habe eine Erinnerung für morgen um 10 Uhr erstellt: 'Meeting mit dem Team'.",
        "evenAIActivated": "Even AI wurde aktiviert. Du kannst jetzt sprechen.",
        "evenAIProcessing": "Ich verarbeite deine Anfrage...",
        "evenAIError": "Es gab einen Fehler bei der Verarbeitung. Bitte versuche es erneut."
    ]
}
