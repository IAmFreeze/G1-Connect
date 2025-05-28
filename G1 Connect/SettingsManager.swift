import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Properties for SwiftUI
    // Display Settings
    @Published var brightness: Int = 50 {
        didSet {
            UserDefaults.standard.set(brightness, forKey: "brightness")
            if !autoBrightness {
                sendBrightnessCommand()
            }
        }
    }
    
    @Published var autoBrightness: Bool = false {
        didSet {
            UserDefaults.standard.set(autoBrightness, forKey: "autoBrightness")
            sendAutoBrightnessCommand()
        }
    }
    
    @Published var contrast: Int = 50 {
        didSet {
            UserDefaults.standard.set(contrast, forKey: "contrast")
            sendContrastCommand()
        }
    }
    
    @Published var colorMode: ColorMode = .standard {
        didSet {
            UserDefaults.standard.set(colorMode.rawValue, forKey: "colorMode")
            sendColorModeCommand()
        }
    }
    
    // HUD Settings
    @Published var hudHeight: Int = 50 {
        didSet {
            UserDefaults.standard.set(hudHeight, forKey: "hudHeight")
            sendHUDHeightCommand()
        }
    }
    
    @Published var hudTransparency: Int = 30 {
        didSet {
            UserDefaults.standard.set(hudTransparency, forKey: "hudTransparency")
            sendHUDTransparencyCommand()
        }
    }
    
    @Published var textSize: TextSize = .medium {
        didSet {
            UserDefaults.standard.set(textSize.rawValue, forKey: "textSize")
            sendTextSizeCommand()
        }
    }
    
    // Power Settings
    @Published var powerSaving: Bool = false {
        didSet {
            UserDefaults.standard.set(powerSaving, forKey: "powerSaving")
            sendPowerSavingCommand()
        }
    }
    
    @Published var autoOff: AutoOffTime = .never {
        didSet {
            UserDefaults.standard.set(autoOff.rawValue, forKey: "autoOff")
            sendAutoOffCommand()
        }
    }
    
    // Connection Settings
    @Published var autoConnect: Bool = true {
        didSet {
            UserDefaults.standard.set(autoConnect, forKey: "autoConnect")
        }
    }
    
    // G1-Specific Settings
    @Published var evenAIEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(evenAIEnabled, forKey: "evenAIEnabled")
        }
    }
    
    @Published var touchBarSensitivity: TouchBarSensitivity = .medium {
        didSet {
            UserDefaults.standard.set(touchBarSensitivity.rawValue, forKey: "touchBarSensitivity")
            sendTouchBarSensitivityCommand()
        }
    }
    
    @Published var displayOrientation: DisplayOrientation = .auto {
        didSet {
            UserDefaults.standard.set(displayOrientation.rawValue, forKey: "displayOrientation")
            sendDisplayOrientationCommand()
        }
    }
    
    // MARK: - Initialization
    private init() {
        loadSettings()
    }
    
    // MARK: - Methods
    private func loadSettings() {
        brightness = UserDefaults.standard.object(forKey: "brightness") as? Int ?? 50
        autoBrightness = UserDefaults.standard.bool(forKey: "autoBrightness")
        contrast = UserDefaults.standard.object(forKey: "contrast") as? Int ?? 50
        
        if let colorModeValue = UserDefaults.standard.object(forKey: "colorMode") as? Int {
            colorMode = ColorMode(rawValue: colorModeValue) ?? .standard
        }
        
        hudHeight = UserDefaults.standard.object(forKey: "hudHeight") as? Int ?? 50
        hudTransparency = UserDefaults.standard.object(forKey: "hudTransparency") as? Int ?? 30
        
        if let textSizeValue = UserDefaults.standard.object(forKey: "textSize") as? Int {
            textSize = TextSize(rawValue: textSizeValue) ?? .medium
        }
        
        powerSaving = UserDefaults.standard.bool(forKey: "powerSaving")
        
        if let autoOffValue = UserDefaults.standard.object(forKey: "autoOff") as? Int {
            autoOff = AutoOffTime(rawValue: autoOffValue) ?? .never
        }
        
        autoConnect = UserDefaults.standard.object(forKey: "autoConnect") as? Bool ?? true
        evenAIEnabled = UserDefaults.standard.object(forKey: "evenAIEnabled") as? Bool ?? true
        
        if let sensitivityValue = UserDefaults.standard.object(forKey: "touchBarSensitivity") as? Int {
            touchBarSensitivity = TouchBarSensitivity(rawValue: sensitivityValue) ?? .medium
        }
        
        if let orientationValue = UserDefaults.standard.object(forKey: "displayOrientation") as? Int {
            displayOrientation = DisplayOrientation(rawValue: orientationValue) ?? .auto
        }
    }
    
    // MARK: - G1 Command Methods (Using Official Protocol)
    
    private func sendBrightnessCommand() {
        guard BluetoothManager.shared.isConnected, !autoBrightness else { return }
        
        let command: [UInt8] = [0xF5, 0x10, UInt8(brightness)]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Brightness command sent: \(brightness)%")
    }
    
    private func sendAutoBrightnessCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let status: UInt8 = autoBrightness ? 1 : 0
        let command: [UInt8] = [0xF5, 0x11, status]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Auto-brightness command sent: \(autoBrightness)")
    }
    
    private func sendContrastCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let command: [UInt8] = [0xF5, 0x12, UInt8(contrast)]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Contrast command sent: \(contrast)%")
    }
    
    private func sendColorModeCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let command: [UInt8] = [0xF5, 0x13, UInt8(colorMode.rawValue)]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Color mode command sent: \(colorMode.displayName)")
    }
    
    private func sendHUDHeightCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let command: [UInt8] = [0xF5, 0x14, UInt8(hudHeight)]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("HUD height command sent: \(hudHeight)%")
    }
    
    private func sendHUDTransparencyCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let command: [UInt8] = [0xF5, 0x15, UInt8(hudTransparency)]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("HUD transparency command sent: \(hudTransparency)%")
    }
    
    private func sendTextSizeCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let command: [UInt8] = [0xF5, 0x16, UInt8(textSize.rawValue)]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Text size command sent: \(textSize.displayName)")
    }
    
    private func sendPowerSavingCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let status: UInt8 = powerSaving ? 1 : 0
        let command: [UInt8] = [0xF5, 0x18, status] // Note: Changed from 0x17 to avoid conflict
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Power saving command sent: \(powerSaving)")
    }
    
    private func sendAutoOffCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let minutes: UInt8
        switch autoOff {
        case .never: minutes = 0
        case .oneMinute: minutes = 1
        case .fiveMinutes: minutes = 5
        case .tenMinutes: minutes = 10
        case .thirtyMinutes: minutes = 30
        case .oneHour: minutes = 60
        }
        
        let command: [UInt8] = [0xF5, 0x19, minutes]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Auto-off command sent: \(autoOff.displayName)")
    }
    
    private func sendTouchBarSensitivityCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let sensitivity: UInt8
        switch touchBarSensitivity {
        case .low: sensitivity = 1
        case .medium: sensitivity = 2
        case .high: sensitivity = 3
        }
        
        let command: [UInt8] = [0xF5, 0x1A, sensitivity]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("TouchBar sensitivity command sent: \(touchBarSensitivity.displayName)")
    }
    
    private func sendDisplayOrientationCommand() {
        guard BluetoothManager.shared.isConnected else { return }
        
        let orientation: UInt8
        switch displayOrientation {
        case .auto: orientation = 0
        case .landscape: orientation = 1
        case .portrait: orientation = 2
        }
        
        let command: [UInt8] = [0xF5, 0x1B, orientation]
        let data = Data(command)
        BluetoothManager.shared.writeDataToG1(data, side: .both)
        
        print("Display orientation command sent: \(displayOrientation.displayName)")
    }
    
    // Send all settings to G1 (used when connecting)
    func sendAllSettings() {
        guard BluetoothManager.shared.isConnected else {
            print("Cannot send settings: G1 not connected")
            return
        }
        
        print("Sending all settings to G1...")
        
        // Add delays between commands to prevent overwhelming the G1
        let commands: [(String, () -> Void)] = [
            ("brightness", sendBrightnessCommand),
            ("auto-brightness", sendAutoBrightnessCommand),
            ("contrast", sendContrastCommand),
            ("color mode", sendColorModeCommand),
            ("HUD height", sendHUDHeightCommand),
            ("HUD transparency", sendHUDTransparencyCommand),
            ("text size", sendTextSizeCommand),
            ("power saving", sendPowerSavingCommand),
            ("auto-off", sendAutoOffCommand),
            ("TouchBar sensitivity", sendTouchBarSensitivityCommand),
            ("display orientation", sendDisplayOrientationCommand)
        ]
        
        for (index, (name, command)) in commands.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                print("Sending \(name) setting...")
                command()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(commands.count) * 0.1 + 0.5) {
            print("All settings sent to G1")
            
            // Send confirmation to G1 display
            G1DisplayManager.shared.sendTextToG1("Einstellungen aktualisiert ✓")
        }
    }
    
    // Reset all settings to defaults
    func resetToDefaults() {
        brightness = 50
        autoBrightness = false
        contrast = 50
        colorMode = .standard
        hudHeight = 50
        hudTransparency = 30
        textSize = .medium
        powerSaving = false
        autoOff = .never
        autoConnect = true
        evenAIEnabled = true
        touchBarSensitivity = .medium
        displayOrientation = .auto
        
        // Send to G1 if connected
        if BluetoothManager.shared.isConnected {
            sendAllSettings()
        }
        
        print("Settings reset to defaults")
    }
    
    // MARK: - G1 Specific Methods
    
    /// Gets current G1 connection info
    var g1ConnectionInfo: G1ConnectionInfo {
        let manager = BluetoothManager.shared
        return G1ConnectionInfo(
            isConnected: manager.isConnected,
            deviceName: manager.connectedDevices.first?.key ?? "Nicht verbunden",
            connectionStatus: manager.connectionStatus,
            isRecording: manager.isRecording
        )
    }
    
    /// Validates G1 settings compatibility
    func validateG1Compatibility() -> [String] {
        var warnings: [String] = []
        
        if brightness > 80 && !autoBrightness {
            warnings.append("Hohe Helligkeit kann die Akkulaufzeit reduzieren")
        }
        
        if hudTransparency < 20 {
            warnings.append("Niedrige Transparenz kann die Sicht beeinträchtigen")
        }
        
        if powerSaving && autoOff == .never {
            warnings.append("Energiesparmodus ohne Auto-Off ist weniger effektiv")
        }
        
        return warnings
    }
}

// MARK: - Supporting Types

struct G1ConnectionInfo {
    let isConnected: Bool
    let deviceName: String
    let connectionStatus: String
    let isRecording: Bool
}

// MARK: - Enums for G1 Settings

enum ColorMode: Int, CaseIterable, Identifiable {
    case standard = 0
    case highContrast = 1
    case night = 2
    case daylight = 3
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .highContrast: return "Hoher Kontrast"
        case .night: return "Nachtmodus"
        case .daylight: return "Tageslicht"
        }
    }
}

enum TextSize: Int, CaseIterable, Identifiable {
    case small = 0
    case medium = 1
    case large = 2
    case extraLarge = 3
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "Klein"
        case .medium: return "Mittel"
        case .large: return "Groß"
        case .extraLarge: return "Sehr groß"
        }
    }
}

enum AutoOffTime: Int, CaseIterable, Identifiable {
    case never = 0
    case oneMinute = 1
    case fiveMinutes = 2
    case tenMinutes = 3
    case thirtyMinutes = 4
    case oneHour = 5
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .never: return "Nie"
        case .oneMinute: return "Nach 1 Minute"
        case .fiveMinutes: return "Nach 5 Minuten"
        case .tenMinutes: return "Nach 10 Minuten"
        case .thirtyMinutes: return "Nach 30 Minuten"
        case .oneHour: return "Nach 1 Stunde"
        }
    }
}

enum TouchBarSensitivity: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        }
    }
}

enum DisplayOrientation: Int, CaseIterable, Identifiable {
    case auto = 0
    case landscape = 1
    case portrait = 2
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .auto: return "Automatisch"
        case .landscape: return "Querformat"
        case .portrait: return "Hochformat"
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
