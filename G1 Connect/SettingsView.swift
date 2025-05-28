import SwiftUI

struct SettingsView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingResetAlert = false
    @State private var showingCompatibilityWarnings = false
    @State private var compatibilityWarnings: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                // G1 Connection Section
                G1ConnectionSection()
                
                // G1 Display Settings
                G1DisplaySection()
                
                // G1 HUD Settings
                G1HUDSection()
                
                // G1 Audio & Interaction
                G1AudioInteractionSection()
                
                // Power Management
                G1PowerSection()
                
                // Advanced Settings
                G1AdvancedSection()
                
                // Reset and Info Section
                ResetInfoSection()
            }
            .listStyle(InsetGroupedListStyle())
            .background(Constants.backgroundColor.ignoresSafeArea())
            .navigationTitle("G1 Einstellungen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Prüfen") {
                        checkCompatibility()
                    }
                }
            }
            .alert("Einstellungen zurücksetzen", isPresented: $showingResetAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Zurücksetzen", role: .destructive) {
                    settingsManager.resetToDefaults()
                }
            } message: {
                Text("Möchten Sie alle Einstellungen auf die Standardwerte zurücksetzen?")
            }
            .alert("Kompatibilitätsprüfung", isPresented: $showingCompatibilityWarnings) {
                Button("OK") { }
            } message: {
                if compatibilityWarnings.isEmpty {
                    Text("Alle Einstellungen sind G1-kompatibel! ✅")
                } else {
                    Text(compatibilityWarnings.joined(separator: "\n\n"))
                }
            }
        }
    }
    
    private func checkCompatibility() {
        compatibilityWarnings = settingsManager.validateG1Compatibility()
        showingCompatibilityWarnings = true
    }
}

// MARK: - G1 Connection Section

struct G1ConnectionSection: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Section(header: Text("G1 Verbindung").foregroundColor(Constants.primaryColor)) {
            // Connection Status
            G1ConnectionStatusView()
            
            // Scan Controls
            if !bluetoothManager.isConnected {
                G1ScanControlsView()
            }
            
            // Available G1 Devices
            if !bluetoothManager.pairedDevices.isEmpty {
                G1DeviceListView()
            }
            
            // Disconnect Button
            if bluetoothManager.isConnected {
                G1DisconnectButtonView()
            }
            
            // Auto-connect Toggle
            Toggle("Automatisch verbinden", isOn: $settingsManager.autoConnect)
            
            // Even AI Toggle
            Toggle("Even AI aktiviert", isOn: $settingsManager.evenAIEnabled)
                .disabled(!bluetoothManager.isConnected)
        }
    }
}

struct G1ConnectionStatusView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        HStack {
            Text("Status")
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(bluetoothManager.isConnected ? Constants.successColor : Constants.errorColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(bluetoothManager.connectionStatus)
                        .foregroundColor(bluetoothManager.isConnected ? Constants.successColor : Constants.secondaryTextColor)
                        .font(.subheadline)
                    
                    if bluetoothManager.isRecording {
                        Text("🎤 Aufnahme")
                            .font(.caption)
                            .foregroundColor(Constants.errorColor)
                    }
                }
            }
        }
    }
}

struct G1ScanControlsView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        Button(action: {
            if bluetoothManager.isScanning {
                bluetoothManager.stopScan()
            } else {
                bluetoothManager.startScan()
            }
        }) {
            HStack {
                Image(systemName: bluetoothManager.isScanning ? "stop.circle" : "magnifyingglass")
                    .foregroundColor(bluetoothManager.isScanning ? Constants.errorColor : Constants.primaryColor)
                
                Text(bluetoothManager.isScanning ? "Scan stoppen" : "Nach G1 Brillen suchen")
                    .foregroundColor(bluetoothManager.isScanning ? Constants.errorColor : Constants.primaryColor)
            }
        }
    }
}

struct G1DeviceListView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        ForEach(Array(bluetoothManager.pairedDevices.keys.sorted()), id: \.self) { deviceName in
            Button(action: {
                bluetoothManager.connectToDevice(deviceName: deviceName)
            }) {
                HStack {
                    Image(systemName: "eyeglasses")
                        .foregroundColor(Constants.primaryColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(deviceName)
                            .foregroundColor(Constants.textColor)
                        
                        Text("Even Realities G1")
                            .font(.caption)
                            .foregroundColor(Constants.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    if bluetoothManager.connectedDevices[deviceName] != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Constants.successColor)
                    } else {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(Constants.secondaryTextColor)
                    }
                }
            }
            .disabled(bluetoothManager.connectedDevices[deviceName] != nil)
        }
    }
}

struct G1DisconnectButtonView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        Button(action: {
            bluetoothManager.disconnectFromGlasses()
        }) {
            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundColor(Constants.errorColor)
                Text("G1 Verbindung trennen")
                    .foregroundColor(Constants.errorColor)
            }
        }
    }
}

// MARK: - G1 Display Section

struct G1DisplaySection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Section(header: Text("G1 Display").foregroundColor(Constants.primaryColor)) {
            // Brightness Control
            G1BrightnessControlView()
            
            // Auto-brightness Toggle
            Toggle("Auto-Helligkeit", isOn: $settingsManager.autoBrightness)
            
            // Contrast Control
            G1ContrastControlView()
            
            // Color Mode Picker
            Picker("Farbmodus", selection: $settingsManager.colorMode) {
                ForEach(ColorMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            
            // Display Orientation
            Picker("Ausrichtung", selection: $settingsManager.displayOrientation) {
                ForEach(DisplayOrientation.allCases) { orientation in
                    Text(orientation.displayName).tag(orientation)
                }
            }
        }
    }
}

struct G1BrightnessControlView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Helligkeit")
                Spacer()
                Text("\(settingsManager.brightness)%")
                    .foregroundColor(Constants.secondaryTextColor)
            }
            
            Slider(
                value: Binding(
                    get: { Double(settingsManager.brightness) },
                    set: { settingsManager.brightness = Int($0) }
                ),
                in: 10...100,
                step: 5
            )
            .disabled(settingsManager.autoBrightness)
            .tint(Constants.primaryColor)
        }
    }
}

struct G1ContrastControlView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Kontrast")
                Spacer()
                Text("\(settingsManager.contrast)%")
                    .foregroundColor(Constants.secondaryTextColor)
            }
            
            Slider(
                value: Binding(
                    get: { Double(settingsManager.contrast) },
                    set: { settingsManager.contrast = Int($0) }
                ),
                in: 0...100,
                step: 5
            )
            .tint(Constants.primaryColor)
        }
    }
}

// MARK: - G1 HUD Section

struct G1HUDSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Section(header: Text("G1 HUD").foregroundColor(Constants.primaryColor)) {
            // HUD Height Control
            G1HUDHeightControlView()
            
            // HUD Transparency Control
            G1HUDTransparencyControlView()
            
            // Text Size Picker
            Picker("Textgröße", selection: $settingsManager.textSize) {
                ForEach(TextSize.allCases) { size in
                    Text(size.displayName).tag(size)
                }
            }
        }
    }
}

struct G1HUDHeightControlView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HUD-Höhe")
                Spacer()
                Text("\(settingsManager.hudHeight)%")
                    .foregroundColor(Constants.secondaryTextColor)
            }
            
            Slider(
                value: Binding(
                    get: { Double(settingsManager.hudHeight) },
                    set: { settingsManager.hudHeight = Int($0) }
                ),
                in: 10...100,
                step: 5
            )
            .tint(Constants.primaryColor)
        }
    }
}

struct G1HUDTransparencyControlView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Transparenz")
                Spacer()
                Text("\(settingsManager.hudTransparency)%")
                    .foregroundColor(Constants.secondaryTextColor)
            }
            
            Slider(
                value: Binding(
                    get: { Double(settingsManager.hudTransparency) },
                    set: { settingsManager.hudTransparency = Int($0) }
                ),
                in: 0...80,
                step: 5
            )
            .tint(Constants.primaryColor)
        }
    }
}

// MARK: - G1 Audio & Interaction Section

struct G1AudioInteractionSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Section(header: Text("Audio & Interaktion").foregroundColor(Constants.primaryColor)) {
            // TouchBar Sensitivity
            Picker("TouchBar Empfindlichkeit", selection: $settingsManager.touchBarSensitivity) {
                ForEach(TouchBarSensitivity.allCases) { sensitivity in
                    Text(sensitivity.displayName).tag(sensitivity)
                }
            }
            
            // Audio Quality Info
            G1AudioQualityInfoView()
        }
    }
}

struct G1AudioQualityInfoView: View {
    @StateObject private var g1AudioManager = G1AudioManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Audio-Format")
                Spacer()
                Text(g1AudioManager.currentAudioFormat)
                    .foregroundColor(Constants.secondaryTextColor)
                    .font(.caption)
            }
            
            HStack {
                Text("Spracherkennung")
                Spacer()
                Text(g1AudioManager.isAudioInputAvailable ? "Verfügbar" : "Nicht verfügbar")
                    .foregroundColor(g1AudioManager.isAudioInputAvailable ? Constants.successColor : Constants.errorColor)
                    .font(.caption)
            }
        }
    }
}

// MARK: - G1 Power Section

struct G1PowerSection: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Section(header: Text("Energieverwaltung").foregroundColor(Constants.primaryColor)) {
            Toggle("Energiesparmodus", isOn: $settingsManager.powerSaving)
            
            Picker("Automatisch ausschalten", selection: $settingsManager.autoOff) {
                ForEach(AutoOffTime.allCases) { time in
                    Text(time.displayName).tag(time)
                }
            }
        }
    }
}

// MARK: - G1 Advanced Section

struct G1AdvancedSection: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        Section(header: Text("Erweitert").foregroundColor(Constants.primaryColor)) {
            // Test Controls
            if bluetoothManager.isConnected {
                Button("G1 Test-Muster senden") {
                    G1DisplayManager.shared.sendTestPattern()
                }
                .foregroundColor(Constants.primaryColor)
                
                Button("Einstellungen synchronisieren") {
                    SettingsManager.shared.sendAllSettings()
                }
                .foregroundColor(Constants.primaryColor)
            }
            
            // Debug Info
            G1DebugInfoView()
        }
    }
}

struct G1DebugInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Debug-Informationen")
                .font(.caption)
                .foregroundColor(Constants.secondaryTextColor)
            
            Text("App Version: \(G1_ConnectApp.fullVersionString)")
                .font(.caption)
                .foregroundColor(Constants.secondaryTextColor)
            
            Text("G1 Protokoll: Even Realities Official")
                .font(.caption)
                .foregroundColor(Constants.secondaryTextColor)
        }
    }
}

// MARK: - Reset and Info Section

struct ResetInfoSection: View {
    @Binding var showingResetAlert: Bool
    
    init(showingResetAlert: Binding<Bool> = .constant(false)) {
        self._showingResetAlert = showingResetAlert
    }
    
    var body: some View {
        Section {
            Button(action: {
                showingResetAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Constants.errorColor)
                    Text("Auf Standardwerte zurücksetzen")
                        .foregroundColor(Constants.errorColor)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}
