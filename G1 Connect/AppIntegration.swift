import Foundation
import CoreBluetooth
import Speech

// Erweiterung der ContentView für die Integration der Brillen-Funktionen
extension ContentView {
    
    /// Erweiterte Setup-Methode für die Brillen-Integration
    func setupAppWithGlassesSupport() {
        // Bestehende Setup-Funktionalität beibehalten
        // Access via viewModel
        if viewModel.settingsManager.autoConnect,
           let lastDevice = UserDefaults.standard.string(forKey: "lastConnectedDevice") {
            viewModel.bluetoothManager.startScan()
            
            // Versuchen, nach kurzer Verzögerung zu verbinden
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Access via viewModel
                self.viewModel.bluetoothManager.connectToDevice(deviceName: lastDevice)
            }
        }
        
        // Spracherkennungs-Berechtigung anfordern
        SpeechRecognizer.requestPermission { [weak viewModel] granted in // Capture viewModel
            guard let strongViewModel = viewModel else { return }
            if granted {
                // Listener für Brillen-Aktivierung hinzufügen
                NotificationCenter.default.addObserver(forName: .lilyActivatedFromGlasses, object: nil, queue: .main) { _ in
                    // Zum Lily-Tab wechseln
                    strongViewModel.selectedTab = 0
                    
                    // Feedback in der App anzeigen
                    // In einer realen Implementierung würde hier ein visuelles Feedback erfolgen
                    print("Lily wurde über die Brille aktiviert")
                }
                
                // Listener für das Ende der Aufnahme hinzufügen
                NotificationCenter.default.addObserver(forName: .lilyRecordingStoppedFromGlasses, object: nil, queue: .main) { _ in
                    // Verarbeitung der Aufnahme starten
                    // In einer realen Implementierung würde hier die Verarbeitung der Aufnahme erfolgen
                    print("Aufnahme über die Brille beendet")
                }
                
                // Brillen-Kommando-Handler registrieren
                // Access via viewModel
                strongViewModel.bluetoothManager.registerGlassesCommandHandlers()
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
        // Assuming lilyViewModel has this method
        lilyViewModel.setResponseWithGlassesUpdate(response)
    }
    
    /// Initialisiert die Brillen-Integration
    func initializeGlassesIntegration() {
        // Brillen-Display-Manager initialisieren
        _ = G1DisplayManager.shared // Corrected typo
        
        // Audio-Manager initialisieren
        _ = AudioManager.shared
        
        // Aktuellen Zustand auf die Brille übertragen, wenn verbunden
        // Access bluetoothManager via its shared instance
        if BluetoothManager.shared.isConnected {
            // Assuming lilyViewModel has this method
            lilyViewModel.updateGlassesDisplay()
        }
    }
}

// Erweiterung der G1_ConnectApp für die Brillen-Integration
extension G1_ConnectApp {
    
    /// Richtet die Brillen-Unterstützung ein
    func setupGlassesSupport() {
        // Brillen-Display-Manager initialisieren
        _ = G1DisplayManager.shared // Corrected typo
        
        // Audio-Manager initialisieren
        _ = AudioManager.shared
        
        // Protokoll-Handler registrieren
        BluetoothManager.shared.registerGlassesCommandHandlers()
    }
}
