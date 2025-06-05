import Foundation
import Speech
import AVFoundation

/// Manager für die Wake-Word-Erkennung auf der G1-Brille
class WakeWordManager: NSObject {
    static let shared = WakeWordManager()
    
    // Wake-Word für die Erkennung
    private var wakeWord: String = Constants.wakeWord
    
    // Callback für erkanntes Wake-Word
    private var wakeWordDetectedHandler: (() -> Void)?
    
    // Status der Wake-Word-Erkennung
    @Published var isListening = false
    
    // Referenz zum AudioManager
    private let audioManager = AudioManager.shared
    
    private override init() {
        super.init()
        print("WakeWordManager initialisiert")
        
        // Als Delegate für den AudioManager registrieren
        audioManager.speechDelegate = self
    }
    
    /// Startet die Wake-Word-Erkennung
    func startWakeWordDetection(wakeWord: String = Constants.wakeWord, onDetection: @escaping () -> Void) {
        self.wakeWord = wakeWord
        self.wakeWordDetectedHandler = onDetection
        self.isListening = true
        
        // SpeechRecognizer für Brillen-Audio konfigurieren
        SpeechRecognizer.shared.startListeningFromGlasses(for: wakeWord) {
            // Wake-Word erkannt, Callback ausführen
            onDetection()
        }
        
        print("Wake-Word-Erkennung gestartet für: \(wakeWord)")
    }
    
    /// Stoppt die Wake-Word-Erkennung
    func stopWakeWordDetection() {
        isListening = false
        SpeechRecognizer.shared.stopListening()
        print("Wake-Word-Erkennung gestoppt")
    }
    
    /// Aktiviert die Brillen-Mikrofon-Aufnahme manuell
    func activateGlassesMicrophoneManually() {
        BluetoothManager.shared.activateGlassesMicrophone()
    }
}

// Implementierung des SpeechRecognitionDelegate
extension WakeWordManager: SpeechRecognitionDelegate {
    func didRecognizeText(_ text: String) {
        // Prüfen, ob der erkannte Text das Wake-Word enthält
        if text.lowercased().contains(wakeWord.lowercased()) {
            didDetectWakeWord()
        }
    }
    
    func didDetectWakeWord() {
        // Wake-Word wurde erkannt
        print("Wake-Word erkannt: \(wakeWord)")
        
        // Callback ausführen
        DispatchQueue.main.async { [weak self] in
            self?.wakeWordDetectedHandler?()
        }
    }
}

// Erweiterung der LilyView für die Wake-Word-Integration
extension LilyView {
    
    /// Initialisiert die Wake-Word-Erkennung
    func setupWakeWordDetection() {
        // Wake-Word-Manager initialisieren
        let wakeWordManager = WakeWordManager.shared
        
        // Wake-Word-Erkennung starten
        wakeWordManager.startWakeWordDetection {
            // Zum Lily-Tab wechseln (falls nicht bereits aktiv)
            // In einer realen Implementierung würde hier der Tab-Wechsel erfolgen
            
            // Lily aktivieren und Feedback anzeigen
            DispatchQueue.main.async {
                // `self` is a copy of LilyView. Accessing `lilyViewModel` (StateObject) is fine.
                self.lilyViewModel.generateRandomResponseWithGlassesUpdate()
                self.lilyViewModel.isInputShowing = true
            }
        }
    }
}

// Erweiterung des BluetoothManager für die Wake-Word-Integration
extension BluetoothManager {
    
    /// Verarbeitet Touch-Events von der Brille für die Wake-Word-Aktivierung
    func processTouchEvent(_ data: Data) {
        // Prüfen, ob es sich um ein langes Drücken der linken TouchBar handelt
        if data.count >= 2 && data[0] == 0xF5 && data[1] == 0x17 {
            print("Langes Drücken der linken TouchBar erkannt")
            
            // Mikrofon aktivieren
            activateGlassesMicrophone()
            
            // Benachrichtigung senden
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .lilyActivatedFromGlasses, object: nil)
            }
        }
        // Prüfen, ob es sich um das Loslassen der TouchBar handelt
        else if data.count >= 2 && data[0] == 0xF5 && data[1] == 0x24 {
            print("Loslassen der TouchBar erkannt")
            
            // Mikrofon deaktivieren
            deactivateGlassesMicrophone()
            
            // Benachrichtigung senden
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .lilyRecordingStoppedFromGlasses, object: nil)
            }
        }
    }
}

// Erweiterung der ContentView für die Wake-Word-Integration
extension ContentView {
    
    /// Richtet die Wake-Word-Erkennung ein
    func setupWakeWordDetection() {
        // Berechtigungen für Spracherkennung anfordern
        SpeechRecognizer.requestPermission { granted in
            if granted {
                // Wake-Word-Erkennung starten
                WakeWordManager.shared.startWakeWordDetection {
                    // Zum Lily-Tab wechseln
                    DispatchQueue.main.async {
                        // `self` is a copy of ContentView. Accessing `viewModel` (StateObject) is fine.
                        self.viewModel.selectedTab = 0
                    }
                }
                
                // Listener für Brillen-Aktivierung hinzufügen
                NotificationCenter.default.addObserver(forName: .lilyActivatedFromGlasses, object: nil, queue: .main) { _ in
                    // Zum Lily-Tab wechseln
                    DispatchQueue.main.async {
                        // `self` is a copy of ContentView. Accessing `viewModel` (StateObject) is fine.
                        self.viewModel.selectedTab = 0
                    }
                }
            }
        }
    }
}
