import Foundation
import CoreBluetooth

// Erweiterung des BluetoothManager für die Mikrofon-Aktivierung und Audioverarbeitung
extension BluetoothManager {
    
    /// Aktiviert das Mikrofon der Brille
    func activateGlassesMicrophone() {
        guard isConnected else {
            print("Fehler: Keine Verbindung zur Brille")
            return
        }
        
        // Kommando [0x0E, 0x01] an die rechte Seite senden
        let command: [UInt8] = [0x0E, 0x01]
        let data = Data(command)
        writeData(writeData: data, lr: "R")
        
        print("Mikrofon-Aktivierungskommando an die Brille gesendet")
    }
    
    /// Deaktiviert das Mikrofon der Brille
    func deactivateGlassesMicrophone() {
        guard isConnected else { return }
        
        // Kommando [0x0E, 0x00] an die rechte Seite senden
        let command: [UInt8] = [0x0E, 0x00]
        let data = Data(command)
        writeData(writeData: data, lr: "R")
        
        print("Mikrofon-Deaktivierungskommando an die Brille gesendet")
    }
    
    /// Registriert Handler für Brillen-Kommandos
    func registerGlassesCommandHandlers() {
        // Diese Methode wird beim App-Start aufgerufen, um die Handler zu registrieren
        print("Brillen-Kommando-Handler registriert")
    }
    
    /// Verarbeitet Brillen-Kommandos
    func processGlassesCommand(_ command: [UInt8]) {
        // Prüfen, ob es sich um das Aktivierungskommando handelt (0xF5, 0x17)
        if command.count >= 2 && command[0] == 0xF5 && command[1] == 0x17 {
            // Brillen-Mikrofon aktivieren
            activateGlassesMicrophone()
            
            // UI-Feedback in der App
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .lilyActivatedFromGlasses, object: nil)
            }
        }
        
        // Prüfen, ob es sich um das Deaktivierungskommando handelt (0xF5, 0x24)
        else if command.count >= 2 && command[0] == 0xF5 && command[1] == 0x24 {
            // Brillen-Mikrofon deaktivieren
            deactivateGlassesMicrophone()
            
            // Audio-Aufnahme beenden und verarbeiten
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .lilyRecordingStoppedFromGlasses, object: nil)
            }
        }
    }
}

// Erweiterung für die Verarbeitung von Audiodaten im CBPeripheralDelegate
extension BluetoothManager {
    
    /// Verarbeitet eingehende Charakteristik-Updates (überschreibt die bestehende Methode)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Fehler beim Aktualisieren des Charakteristikwerts: \(error!.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        // Prüfen, ob es sich um Audiodaten handelt (Kommando 0xF1)
        if data.count > 2 && data[0] == 0xF1 {
            let sequenceNumber = data[1]
            let audioData = data.subdata(in: 2..<data.count)
            
            // Audiodaten an den AudioManager weiterleiten
            AudioManager.shared.processAudioFromGlasses(audioData, sequenceNumber: sequenceNumber)
        }
        
        // Prüfen, ob es sich um eine Kommandoantwort handelt
        else if data.count > 1 && data[0] == 0x0E {
            let status = data[1]
            let enable = data.count > 2 ? data[2] : 0
            
            if status == 0xC9 {
                print("Mikrofon-Kommando erfolgreich: \(enable == 1 ? "aktiviert" : "deaktiviert")")
            } else if status == 0xCA {
                print("Mikrofon-Kommando fehlgeschlagen: \(enable == 1 ? "Aktivierung" : "Deaktivierung")")
            }
        }
        
        // Andere Kommandos verarbeiten
        else if data.count > 1 {
            processGlassesCommand([UInt8](data))
        }
    }
}

// Erweiterung für Notification.Name
extension Notification.Name {
    static let lilyActivatedFromGlasses = Notification.Name("lilyActivatedFromGlasses")
    static let lilyRecordingStoppedFromGlasses = Notification.Name("lilyRecordingStoppedFromGlasses")
}
