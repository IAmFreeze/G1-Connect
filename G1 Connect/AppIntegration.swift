import Foundation
import CoreBluetooth
import Speech

// Erweiterung der ContentView für die Integration der Brillen-Funktionen
extension ContentView {
    
    /// Erweiterte Setup-Methode für die Brillen-Integration
    func setupAppWithGlassesSupport() {
        // Bestehende Setup-Funktionalität beibehalten
        if settingsManager.autoConnect,
           let lastDevice = UserDefaults.standard.string(forKey: "lastConnectedDevice") {
            bluetoothManager.startScan()
            
            // Versuchen, nach kurzer Verzögerung zu verbinden
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                bluetoothManager.connectToDevice(deviceName: lastDevice)
            }
        }
        
        // Spracherkennungs-Berechtigung anfordern
        SpeechRecognizer.requestPermission { granted in
            if granted {
                // Listener für Brillen-Aktivierung hinzufügen
                NotificationCenter.default.addObserver(forName: .lilyActivatedFromGlasses, object: nil, queue: .main) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Zum Lily-Tab wechseln
                    self.selectedTab = 0
                    
                    // Feedback in der App anzeigen
                    // In einer realen Implementierung würde hier ein visuelles Feedback erfolgen
                    print("Lily wurde über die Brille aktiviert")
                }
                
                // Listener für das Ende der Aufnahme hinzufügen
                NotificationCenter.default.addObserver(forName: .lilyRecordingStoppedFromGlasses, object: nil, queue: .main) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Verarbeitung der Aufnahme starten
                    // In einer realen Implementierung würde hier die Verarbeitung der Aufnahme erfolgen
                    print("Aufnahme über die Brille beendet")
                }
                
                // Brillen-Kommando-Handler registrieren
                bluetoothManager.registerGlassesCommandHandlers()
            }
        }
    }
}

// Erweiterung der LilyView für die Integration der Brillen-Funktionen
extension LilyView {
    
    /// Verarbeitet Benutzereingaben von der Brille
    func processGlassesInput(_ input: String) {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let response = LilyResponse.processInput(input)
        lilyViewModel.setResponseWithGlassesUpdate(response)
    }
    
    /// Initialisiert die Brillen-Integration
    func initializeGlassesIntegration() {
        // Brillen-Display-Manager initialisieren
        _ = BrilleDisplayManager.shared
        
        // Audio-Manager initialisieren
        _ = AudioManager.shared
        
        // Aktuellen Zustand auf die Brille übertragen, wenn verbunden
        if bluetoothManager.isConnected {
            lilyViewModel.updateGlassesDisplay()
        }
    }
}

// Erweiterung der G1_ConnectApp für die Brillen-Integration
extension G1_ConnectApp {
    
    /// Richtet die Brillen-Unterstützung ein
    func setupGlassesSupport() {
        // Brillen-Display-Manager initialisieren
        _ = BrilleDisplayManager.shared
        
        // Audio-Manager initialisieren
        _ = AudioManager.shared
        
        // Protokoll-Handler registrieren
        BluetoothManager.shared.registerGlassesCommandHandlers()
    }
}
