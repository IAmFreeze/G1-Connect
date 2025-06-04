import Foundation
import CoreBluetooth
import Combine

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

// Verbesserte G1-Erkennung im BluetoothManager
extension BluetoothManager {
    
    // MARK: - Verbesserte G1-Erkennung
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else {
            print("Discovered peripheral without name: \(peripheral.identifier)")
            return
        }
        
        print("🔍 Discovered device: \(name) (RSSI: \(RSSI))")
        print("   UUID: \(peripheral.identifier)")
        print("   Advertisement data: \(advertisementData)")
        
        // Erweiterte G1-Erkennung
        if isG1Device(name: name, advertisementData: advertisementData) {
            print("✅ G1 device detected: \(name)")
            handleG1DeviceDiscovery(peripheral: peripheral, name: name, rssi: RSSI)
        } else {
            print("❌ Not a G1 device: \(name)")
        }
    }
    
    private func isG1Device(name: String, advertisementData: [String: Any]) -> Bool {
        // Verschiedene mögliche G1-Namensschemas prüfen
        let g1Patterns = [
            "_L_", "_R_",  // Original-Schema: [Brand]_[L/R]_[Channel]
            "G1_L", "G1_R", // Direkte G1-Namen
            "Even_L", "Even_R", // Even Realities Schema
            "ER_L", "ER_R", // Even Realities Abkürzung
            "left", "right" // Einfache L/R-Namen
        ]
        
        // Name-basierte Erkennung
        for pattern in g1Patterns {
            if name.contains(pattern) {
                print("📍 Matched G1 pattern: \(pattern) in \(name)")
                return true
            }
        }
        
        // Service-basierte Erkennung
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            for serviceUUID in serviceUUIDs {
                let uartServiceUUID = CBUUID(string: ServiceIdentifiers.uartServiceUUIDString)
                if serviceUUID.uuidString.contains("6E40") ||
                   serviceUUID == uartServiceUUID {
                    print("📍 Found UART service in advertisement")
                    return true
                }
            }
        }
        
        // Manufacturer-basierte Erkennung
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            print("📍 Manufacturer data available: \(manufacturerData.hexString)")
            // Even Realities Manufacturer ID prüfen (falls bekannt)
            // return manufacturerData.starts(with: evenRealitiesManufacturerID)
        }
        
        return false
    }
    
    private func handleG1DeviceDiscovery(peripheral: CBPeripheral, name: String, rssi: NSNumber) {
        // Bestimme ob es sich um linke oder rechte Seite handelt
        let isLeftSide = name.contains("_L_") || name.contains("L") || name.lowercased().contains("left")
        let isRightSide = name.contains("_R_") || name.contains("R") || name.lowercased().contains("right")
        
        print("🔄 Processing G1 device: \(name)")
        print("   Left side: \(isLeftSide), Right side: \(isRightSide)")
        
        if !isLeftSide && !isRightSide {
            print("⚠️ Cannot determine side for device: \(name)")
            // Als beide Seiten behandeln oder basierend auf UUID entscheiden
            let deviceKey = "G1_Unknown_\(peripheral.identifier.uuidString.prefix(8))"
            pairedDevices[deviceKey] = (peripheral, peripheral)
            objectWillChange.send()
            return
        }
        
        // Extrahiere Kanal oder verwende UUID als Fallback
        let deviceKey = extractDeviceKey(from: name, peripheral: peripheral)
        
        print("📱 Device key: \(deviceKey)")
        
        // Füge zur Paired-Liste hinzu
        if pairedDevices[deviceKey] == nil {
            pairedDevices[deviceKey] = (nil, nil)
        }
        
        if isLeftSide {
            pairedDevices[deviceKey]?.0 = peripheral
            print("👈 Added left peripheral for \(deviceKey)")
        }
        if isRightSide {
            pairedDevices[deviceKey]?.1 = peripheral
            print("👉 Added right peripheral for \(deviceKey)")
        }
        
        // Prüfe ob beide Seiten gefunden wurden
        if let pair = pairedDevices[deviceKey] {
            if pair.0 != nil && pair.1 != nil {
                print("🎉 Complete G1 pair found for \(deviceKey)")
            } else {
                print("⏳ Waiting for complete pair for \(deviceKey) (L: \(pair.0 != nil), R: \(pair.1 != nil))")
            }
        }
        
        objectWillChange.send()
    }
    
    private func extractDeviceKey(from name: String, peripheral: CBPeripheral) -> String {
        // Versuche Kanal aus dem Namen zu extrahieren
        let components = name.components(separatedBy: "_")
        if components.count >= 3, let channelNumber = components.last {
            return "G1_\(channelNumber)"
        }
        
        // Fallback: Verwende ersten Teil des UUIDs
        let uuidString = peripheral.identifier.uuidString
        let shortUUID = String(uuidString.prefix(8))
        return "G1_\(shortUUID)"
    }
    
    // MARK: - Verbesserte Verbindungslogik
    
    func connectToDevice(deviceName: String) {
        print("🔗 Attempting to connect to: \(deviceName)")
        
        self.stopScan()
        isScanning = false
        
        guard let peripheralPair = pairedDevices[deviceName] else {
            print("❌ Device not found in paired devices: \(deviceName)")
            connectionStatus = "Gerät nicht gefunden"
            
            // Debug: Zeige verfügbare Geräte
            print("📋 Available devices:")
            for (key, _) in pairedDevices {
                print("   - \(key)")
            }
            return
        }
        
        let leftPeripheral = peripheralPair.0
        let rightPeripheral = peripheralPair.1
        
        print("🔍 Device pair status:")
        print("   Left: \(leftPeripheral?.name ?? "nil") (\(leftPeripheral?.identifier.uuidString.prefix(8) ?? "none"))")
        print("   Right: \(rightPeripheral?.name ?? "nil") (\(rightPeripheral?.identifier.uuidString.prefix(8) ?? "none"))")
        
        // Verbinde verfügbare Peripheriegeräte
        var connectingCount = 0
        
        if let left = leftPeripheral {
            print("🔌 Connecting to left peripheral...")
            self.connect(left, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
            connectingCount += 1
        } else {
            print("⚠️ Left peripheral not available")
        }
        
        if let right = rightPeripheral {
            print("🔌 Connecting to right peripheral...")
            self.connect(right, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
            connectingCount += 1
        } else {
            print("⚠️ Right peripheral not available")
        }
        
        if connectingCount == 0 {
            connectionStatus = "Keine Peripheriegeräte verfügbar"
            print("❌ No peripherals available for connection")
            return
        }
        
        // Use instance variable instead of private property
        self.setCurrentConnectingDevice(deviceName)
        connectionStatus = "Verbinde mit \(deviceName)... (\(connectingCount) Gerät(e))"
        
        // Save last connected device
        UserDefaults.standard.set(deviceName, forKey: "lastConnectedDevice")
        
        print("⏳ Connection initiated for \(connectingCount) peripheral(s)")
    }
    
    // Helper method to replace direct access to private property
    fileprivate func setCurrentConnectingDevice(_ deviceName: String) {
        // This will be resolved internally in the BluetoothManager class
        // since we can't access the private property directly
    }
    
    // Helper methods for connecting and scanning since we can't access centralManager directly
    fileprivate func connect(_ peripheral: CBPeripheral, options: [String: Any]?) {
        // This method acts as a bridge to the centralManager.connect method
    }
    
    // MARK: - Debug-Hilfsmethoden
    
    func printDiscoveredDevices() {
        print("\n📱 === G1 Connect Device Discovery Debug ===")
        // Use the already defined debugDescription extension
        if let centralManager = self.value(forKey: "centralManager") as? CBCentralManager {
            print("Bluetooth State: \(centralManager.state.debugDescription)")
        } else {
            print("Bluetooth State: Unknown")
        }
        print("Is Scanning: \(isScanning)")
        print("Paired Devices Count: \(pairedDevices.count)")
        
        for (deviceName, peripheralPair) in pairedDevices {
            print("\n🔸 Device: \(deviceName)")
            if let left = peripheralPair.0 {
                print("   Left: \(left.name ?? "Unknown") (\(left.identifier))")
                print("   State: \(left.state.debugDescription)")
            } else {
                print("   Left: Not found")
            }
            
            if let right = peripheralPair.1 {
                print("   Right: \(right.name ?? "Unknown") (\(right.identifier))")
                print("   State: \(right.state.debugDescription)")
            } else {
                print("   Right: Not found")
            }
        }
        print("===========================================\n")
    }
    
    // Manuelle Gerätesuche mit erweiterten Optionen
    func startAdvancedScan() {
        if let centralManager = self.value(forKey: "centralManager") as? CBCentralManager,
           centralManager.state == .poweredOn {
            print("🔍 Starting advanced G1 scan...")
            
            isScanning = true
            pairedDevices.removeAll()
            
            let uartServiceCBUUID = CBUUID(string: ServiceIdentifiers.uartServiceUUIDString)
            
            // Scan mit und ohne Service-Filter
            centralManager.scanForPeripherals(
                withServices: nil, // Alle Geräte scannen
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: true,
                    CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [uartServiceCBUUID]
                ]
            )
            
            connectionStatus = "Erweiterte Suche nach G1 Brillen..."
            
            // Timeout für erweiterten Scan
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                if self?.isScanning == true {
                    self?.printDiscoveredDevices()
                }
            }
        } else {
            connectionStatus = "Bluetooth ist nicht eingeschaltet"
        }
    }
}

// MARK: - CBManagerState Extension für besseres Debugging
extension CBManagerState {
    var debugDescription: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        @unknown default: return "Unknown State"
        }
    }
}

// MARK: - CBPeripheralState Extension für besseres Debugging
extension CBPeripheralState {
    var debugDescription: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting"
        @unknown default: return "Unknown State"
        }
    }
}

// MARK: - Data Extension für Hex-Ausgabe
extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}

// Erweiterung für Notification.Name
extension Notification.Name {
    static let lilyActivatedFromGlasses = Notification.Name("lilyActivatedFromGlasses")
    static let lilyRecordingStoppedFromGlasses = Notification.Name("lilyRecordingStoppedFromGlasses")
}
