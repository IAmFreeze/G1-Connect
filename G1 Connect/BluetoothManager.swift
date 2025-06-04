import Foundation
import UIKit
import SwiftUI
import Combine
import CoreBluetooth

enum BluetoothError: Error {
    case notPoweredOn
    case deviceNotFound
    case connectionFailed
    case writeError
    case invalidCommand
    
    var localizedDescription: String {
        switch self {
        case .notPoweredOn: return "Bluetooth ist nicht eingeschaltet"
        case .deviceNotFound: return "Gerät nicht gefunden"
        case .connectionFailed: return "Verbindung fehlgeschlagen"
        case .writeError: return "Fehler beim Senden der Daten"
        case .invalidCommand: return "Ungültiger Befehl"
        }
    }
}

enum G1Side {
    case left, right, both
}

enum TouchBarSide {
    case left, right
}

class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    
    // Published properties for SwiftUI
    @Published var isScanning = false
    @Published var pairedDevices: [String: (CBPeripheral?, CBPeripheral?)] = [:]
    @Published var connectedDevices: [String: (CBPeripheral?, CBPeripheral?)] = [:]
    @Published var connectionStatus = "Nicht verbunden"
    @Published var isRecording = false
    
    // Computed property for connection status
    var isConnected: Bool {
        return !connectedDevices.isEmpty &&
               connectedDevices.values.contains { $0.0 != nil && $0.1 != nil }
    }
    
    // Core Bluetooth properties
    private var centralManager: CBCentralManager!
    private var currentConnectingDeviceName: String?
    private var leftPeripheral: CBPeripheral?
    private var leftUUIDStr: String?
    private var rightPeripheral: CBPeripheral?
    private var rightUUIDStr: String?
    private var UARTServiceUUID: CBUUID
    private var UARTRXCharacteristicUUID: CBUUID
    private var UARTTXCharacteristicUUID: CBUUID
    private var leftWChar: CBCharacteristic?
    private var rightWChar: CBCharacteristic?
    private var leftRChar: CBCharacteristic?
    private var rightRChar: CBCharacteristic?
    
    // G1 Protocol specific
    private var pendingLeftAcknowledgment = false
    private var commandQueue: [Data] = []
    
    // Delegates
    weak var audioDelegate: G1AudioDelegate?
    weak var touchBarDelegate: G1TouchBarDelegate?
    
    private override init() {
        UARTServiceUUID = CBUUID(string: ServiceIdentifiers.uartServiceUUIDString)
        UARTTXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartTXCharacteristicUUIDString)
        UARTRXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartRXCharacteristicUUIDString)
        
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Setup notification observers for G1 commands
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEvenAIActivation),
            name: .evenAIActivated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEvenAIStop),
            name: .evenAIStopped,
            object: nil
        )
    }
    
    @objc private func handleEvenAIActivation() {
        activateG1Microphone()
    }
    
    @objc private func handleEvenAIStop() {
        deactivateG1Microphone()
    }
    
    // MARK: - Scanning and Connection
    
    func startScan() {
        guard centralManager.state == .poweredOn else {
            connectionStatus = "Bluetooth ist nicht eingeschaltet"
            return
        }
        
        isScanning = true
        pairedDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        connectionStatus = "Suche nach G1 Brillen..."
    }
    
    func stopScan() {
        isScanning = false
        centralManager.stopScan()
        connectionStatus = "Scan gestoppt"
    }
    
    
    func disconnectFromGlasses() {
        for (_, devices) in connectedDevices {
            if let leftPeripheral = devices.0 {
                centralManager.cancelPeripheralConnection(leftPeripheral)
            }
            if let rightPeripheral = devices.1 {
                centralManager.cancelPeripheralConnection(rightPeripheral)
            }
        }
        
        connectedDevices.removeAll()
        connectionStatus = "Alle Geräte getrennt"
        isRecording = false
    }
    
    // MARK: - G1 Protocol Commands
    
    /// Activates G1 microphone using official protocol
    func activateG1Microphone() {
        guard isConnected else {
            print("Error: No connection to G1")
            return
        }
        
        let command = Data(Constants.G1Commands.microphoneEnable)
        writeDataToG1(command, side: .right) // Microphone activation goes to right side only
        
        isRecording = true
        print("G1 microphone activation command sent")
    }
    
    /// Deactivates G1 microphone using official protocol
    func deactivateG1Microphone() {
        guard isConnected else { return }
        
        let command = Data(Constants.G1Commands.microphoneDisable)
        writeDataToG1(command, side: .right) // Microphone deactivation goes to right side only
        
        isRecording = false
        print("G1 microphone deactivation command sent")
    }
    
    /// Sends text to G1 using official text protocol
    func sendTextToG1(_ text: String) {
        guard isConnected else {
            print("Error: No connection to G1")
            return
        }
        
        // Split text into lines based on G1 display width
        let lines = splitTextIntoLines(text,
                                     maxWidth: Constants.G1Display.maxTextWidth,
                                     fontSize: Constants.G1Display.recommendedFontSize)
        
        // Split lines into screens
        let screens = splitLinesIntoScreens(lines,
                                          linesPerScreen: Constants.G1Display.linesPerScreen)
        
        // Send screens sequentially
        for (pageIndex, screen) in screens.enumerated() {
            sendScreenToG1(screen,
                          currentPage: pageIndex,
                          totalPages: screens.count)
            
            // Add delay between screens to prevent overwhelming
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    /// Sends 1-bit BMP image to G1 using official image protocol
    func sendImageToG1(_ bmpData: Data) {
        guard isConnected else {
            print("Error: No connection to G1")
            return
        }
        
        let packetSize = Constants.G1Display.imagePacketSize
        let totalPackets = (bmpData.count + packetSize - 1) / packetSize
        
        // Send image packets
        for i in 0..<totalPackets {
            let start = i * packetSize
            let end = min(start + packetSize, bmpData.count)
            let packetData = bmpData.subdata(in: start..<end)
            
            var commandData = Data([Constants.G1Commands.imagePacket, UInt8(i & 0xff)])
            
            // Add storage address for first packet
            if i == 0 {
                commandData.append(contentsOf: Constants.G1Display.imageStorageAddress)
            }
            
            commandData.append(packetData)
            
            // Send to both sides as per G1 protocol
            writeDataToG1(commandData, side: .both)
        }
        
        // Send end command
        let endCommand = Data(Constants.G1Commands.imageEnd)
        writeDataToG1(endCommand, side: .both)
        
        // Send CRC command (simplified implementation)
        let crcCommand = Data([Constants.G1Commands.imageCRC, 0x00])
        writeDataToG1(crcCommand, side: .both)
    }
    
    // MARK: - G1 Data Writing (Public Methods)
    
    func writeDataToG1(_ data: Data, side: G1Side) {
        switch side {
        case .left:
            writeToLeft(data)
        case .right:
            writeToRight(data)
        case .both:
            // G1 protocol: send to left first, then right after acknowledgment
            writeToLeft(data)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.writeToRight(data)
            }
        }
    }
    
    // Legacy compatibility method
    func writeData(writeData: Data, lr: String) {
        if lr == "L" {
            writeToLeft(writeData)
        } else if lr == "R" {
            writeToRight(writeData)
        }
    }
    
    private func writeToLeft(_ data: Data) {
        if let leftWChar = leftWChar, let leftPeripheral = leftPeripheral {
            leftPeripheral.writeValue(data, for: leftWChar, type: .withoutResponse)
        } else {
            print("Left characteristic not available")
        }
    }
    
    private func writeToRight(_ data: Data) {
        if let rightWChar = rightWChar, let rightPeripheral = rightPeripheral {
            rightPeripheral.writeValue(data, for: rightWChar, type: .withoutResponse)
        } else {
            print("Right characteristic not available")
        }
    }
    
    
    private func sendScreenToG1(_ screen: [String], currentPage: Int, totalPages: Int) {
        let screenText = screen.joined(separator: "\n")
        
        var commandData = Data([Constants.G1Commands.textDisplay])
        
        // Add protocol parameters as per G1 specification
        commandData.append(UInt8(currentPage & 0xff)) // sequence number
        commandData.append(UInt8(1)) // total package count
        commandData.append(UInt8(0)) // current package number
        commandData.append(Constants.G1Display.newContentTextShow) // screen status
        commandData.append(UInt8(0)) // new char position high
        commandData.append(UInt8(0)) // new char position low
        commandData.append(UInt8(currentPage)) // current page
        commandData.append(UInt8(totalPages)) // max page
        
        // Add text data
        if let textData = screenText.data(using: .utf8) {
            commandData.append(textData)
        }
        
        writeDataToG1(commandData, side: .both)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Bluetooth ist eingeschaltet"
        case .poweredOff:
            connectionStatus = "Bluetooth ist ausgeschaltet"
        case .resetting:
            connectionStatus = "Bluetooth wird zurückgesetzt"
        case .unauthorized:
            connectionStatus = "Bluetooth nicht autorisiert"
        case .unsupported:
            connectionStatus = "Bluetooth nicht unterstützt"
        case .unknown:
            connectionStatus = "Bluetooth-Status unbekannt"
        @unknown default:
            connectionStatus = "Bluetooth-Status unbekannt"
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let deviceName = currentConnectingDeviceName,
              let peripheralPair = pairedDevices[deviceName] else { return }
        
        if connectedDevices[deviceName] == nil {
            connectedDevices[deviceName] = (nil, nil)
        }
        
        if peripheralPair.0 === peripheral {
            connectedDevices[deviceName]?.0 = peripheral
            self.leftPeripheral = peripheral
            self.leftPeripheral?.delegate = self
            self.leftPeripheral?.discoverServices([UARTServiceUUID])
            self.leftUUIDStr = peripheral.identifier.uuidString
            print("Left G1 peripheral connected: \(peripheral.identifier.uuidString)")
        } else if peripheralPair.1 === peripheral {
            connectedDevices[deviceName]?.1 = peripheral
            self.rightPeripheral = peripheral
            self.rightPeripheral?.delegate = self
            self.rightPeripheral?.discoverServices([UARTServiceUUID])
            self.rightUUIDStr = peripheral.identifier.uuidString
            print("Right G1 peripheral connected: \(peripheral.identifier.uuidString)")
        }
        
        // Check if both sides are connected
        if let connectedPair = connectedDevices[deviceName],
           connectedPair.0 != nil && connectedPair.1 != nil {
            connectionStatus = "G1 \(deviceName) verbunden"
            currentConnectingDeviceName = nil
            objectWillChange.send()
            
            // Post connection notification
            NotificationCenter.default.post(name: .g1Connected, object: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("G1 peripheral disconnected: \(peripheral.identifier.uuidString)")
        
        if let error = error {
            print("Disconnect error: \(error.localizedDescription)")
        }
        
        // Update connection status
        if peripheral === leftPeripheral || peripheral === rightPeripheral {
            connectionStatus = "G1 Verbindung getrennt"
            isRecording = false
            objectWillChange.send()
            
            // Post disconnection notification
            NotificationCenter.default.post(name: .g1Disconnected, object: nil)
        }
        
        // Auto-reconnect logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to G1 peripheral: \(error?.localizedDescription ?? "Unknown error")")
        connectionStatus = "Verbindung zu G1 fehlgeschlagen"
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid.isEqual(UARTServiceUUID) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        if service.uuid.isEqual(UARTServiceUUID) {
            for characteristic in characteristics {
                if characteristic.uuid.isEqual(UARTRXCharacteristicUUID) {
                    // RX characteristic (read from glasses)
                    if peripheral.identifier.uuidString == self.leftUUIDStr {
                        self.leftRChar = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                    } else if peripheral.identifier.uuidString == self.rightUUIDStr {
                        self.rightRChar = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                } else if characteristic.uuid.isEqual(UARTTXCharacteristicUUID) {
                    // TX characteristic (write to glasses)
                    if peripheral.identifier.uuidString == self.leftUUIDStr {
                        self.leftWChar = characteristic
                    } else if peripheral.identifier.uuidString == self.rightUUIDStr {
                        self.rightWChar = characteristic
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Write error to G1: \(error.localizedDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Notification state update error: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("Notifications enabled for characteristic: \(characteristic.uuid)")
        } else {
            print("Notifications disabled for characteristic: \(characteristic.uuid)")
        }
    }
    
    // COMBINED didUpdateValueFor method - handles all G1 communication
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else {
            if let error = error {
                print("Error updating characteristic value: \(error.localizedDescription)")
            }
            return
        }
        
        // Process G1 commands and data
        processG1Data(data, from: peripheral)
    }
    
    // MARK: - G1 Data Processing
    
    private func processG1Data(_ data: Data, from peripheral: CBPeripheral) {
        guard data.count > 0 else { return }
        
        let bytes = [UInt8](data)
        
        switch bytes[0] {
        case Constants.G1Commands.dashboardControl:
            // TouchBar commands from glasses
            if data.count >= 2 {
                processTouchBarCommand(bytes)
            }
            
        case Constants.G1Commands.audioStream:
            // Audio stream from glasses
            if data.count >= 3 {
                let sequenceNumber = bytes[1]
                let audioData = data.subdata(in: 2..<data.count)
                audioDelegate?.didReceiveAudioData(audioData, sequenceNumber: sequenceNumber)
            }
            
        case Constants.G1Commands.microphoneCommand:
            // Microphone command response
            if data.count >= 3 {
                let status = bytes[1]
                let enabled = bytes[2]
                processMicrophoneResponse(status: status, enabled: enabled)
            }
            
        default:
            print("Unknown G1 command: \(String(format: "0x%02X", bytes[0]))")
        }
    }
    
    private func processTouchBarCommand(_ bytes: [UInt8]) {
        guard bytes.count >= 2 else { return }
        
        switch bytes[1] {
        case 0x17: // Even AI activation (long press left)
            NotificationCenter.default.post(name: .evenAIActivated, object: nil)
            touchBarDelegate?.didActivateEvenAI()
            
        case 0x24: // Even AI stop (release)
            NotificationCenter.default.post(name: .evenAIStopped, object: nil)
            touchBarDelegate?.didStopEvenAI()
            
        case 0x01: // Page navigation
            touchBarDelegate?.didTapTouchBar(side: .left) // Simplified - should distinguish left/right
            
        case 0x00: // Exit to dashboard
            touchBarDelegate?.didExitToDashboard()
            
        default:
            print("Unknown TouchBar command: \(String(format: "0x%02X", bytes[1]))")
        }
    }
    
    private func processMicrophoneResponse(status: UInt8, enabled: UInt8) {
        if status == Constants.G1Response.microphoneSuccess {
            let action = enabled == 1 ? "activated" : "deactivated"
            print("G1 microphone \(action) successfully")
            DispatchQueue.main.async {
                self.isRecording = enabled == 1
            }
        } else if status == Constants.G1Response.microphoneFailure {
            let action = enabled == 1 ? "activation" : "deactivation"
            print("G1 microphone \(action) failed")
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
}

// MARK: - Protocols

protocol G1AudioDelegate: AnyObject {
    func didReceiveAudioData(_ data: Data, sequenceNumber: UInt8)
}

protocol G1TouchBarDelegate: AnyObject {
    func didActivateEvenAI()
    func didStopEvenAI()
    func didTapTouchBar(side: TouchBarSide)
    func didExitToDashboard()
}

// MARK: - Notifications

extension Notification.Name {
    static let evenAIActivated = Notification.Name("evenAIActivated")
    static let evenAIStopped = Notification.Name("evenAIStopped")
    static let g1Connected = Notification.Name("g1Connected")
    static let g1Disconnected = Notification.Name("g1Disconnected")
}
