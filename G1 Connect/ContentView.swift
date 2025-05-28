import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var g1AudioManager = G1AudioManager.shared
    @StateObject private var lilyAIManager = LilyAIManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LilyView()
                .tabItem {
                    Label("Lily", systemImage: "person.circle")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape")
                }
                .tag(1)
            
            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(2)
        }
        .accentColor(Constants.primaryColor)
        .onAppear {
            setupG1App()
        }
        .onReceive(NotificationCenter.default.publisher(for: .evenAIActivated)) { _ in
            // Switch to Lily tab when Even AI is activated from G1
            selectedTab = 0
        }
    }
    
    private func setupG1App() {
        print("Setting up G1 Connect App...")
        
        // Setup TouchBar delegate
        bluetoothManager.touchBarDelegate = self
        
        // Setup speech recognition delegate
        g1AudioManager.speechDelegate = self
        
        // Auto-connect to last G1 device if enabled
        if settingsManager.autoConnect,
           let lastDevice = UserDefaults.standard.string(forKey: "lastConnectedDevice") {
            
            print("Auto-connecting to last G1 device: \(lastDevice)")
            bluetoothManager.startScan()
            
            // Try to connect after scan discovers devices
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                bluetoothManager.connectToDevice(deviceName: lastDevice)
            }
        }
        
        // Request speech recognition permission
        requestSpeechPermission()
        
        // Setup Even AI listeners
        setupEvenAIListeners()
        
        print("G1 Connect App setup complete")
    }
    
    private func requestSpeechPermission() {
        G1AudioManager.requestSpeechPermission { granted in
            if granted {
                print("Speech recognition permission granted")
            } else {
                print("Speech recognition permission denied")
            }
        }
    }
    
    private func setupEvenAIListeners() {
        // Listen for Even AI activation
        NotificationCenter.default.addObserver(
            forName: .evenAIActivated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleEvenAIActivation()
        }
        
        // Listen for Even AI stop
        NotificationCenter.default.addObserver(
            forName: .evenAIStopped,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleEvenAIStop()
        }
        
        // Listen for G1 connection changes
        NotificationCenter.default.addObserver(
            forName: .g1Connected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleG1Connected()
        }
    }
    
    private func handleEvenAIActivation() {
        print("Even AI activated from G1")
        
        // Switch to Lily tab
        selectedTab = 0
        
        // Show activation status on G1
        G1DisplayManager.shared.displayEvenAIStatus(.activated)
        
        // Start audio processing
        g1AudioManager.startEvenAIProcessing()
        
        // Generate activation response
        let activationResponse = lilyAIManager.generateRandomActivationResponse()
        
        // Show on G1 display
        G1DisplayManager.shared.updateLilyDisplay(
            emotion: activationResponse.emotion,
            message: activationResponse.text
        )
    }
    
    private func handleEvenAIStop() {
        print("Even AI stopped from G1")
        
        // Stop audio processing
        g1AudioManager.stopEvenAIProcessing()
        
        // Show completion status
        G1DisplayManager.shared.displayEvenAIStatus(.complete)
    }
    
    private func handleG1Connected() {
        print("G1 glasses connected")
        
        // Send current settings to G1
        settingsManager.sendAllSettings()
        
        // Send test pattern to verify connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            G1DisplayManager.shared.sendTestPattern()
        }
        
        // Show welcome message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let welcomeResponse = LilyResponse(
                text: "G1 Connect ist bereit! Sage 'Hey Lily' oder drücke die TouchBar, um mich zu aktivieren.",
                emotion: .happy
            )
            
            G1DisplayManager.shared.updateLilyDisplay(
                emotion: welcomeResponse.emotion,
                message: welcomeResponse.text
            )
        }
    }
}

// MARK: - G1TouchBarDelegate

extension ContentView: G1TouchBarDelegate {
    func didActivateEvenAI() {
        print("TouchBar: Even AI activated")
        // Handled by notification system
    }
    
    func didStopEvenAI() {
        print("TouchBar: Even AI stopped")
        // Handled by notification system
    }
    
    func didTapTouchBar(side: TouchBarSide) {
        print("TouchBar tapped: \(side)")
        
        switch side {
        case .left:
            // Handle left TouchBar tap (e.g., previous page, dashboard navigation)
            handleLeftTouchBarTap()
        case .right:
            // Handle right TouchBar tap (e.g., next page, QuickNote)
            handleRightTouchBarTap()
        }
    }
    
    func didExitToDashboard() {
        print("TouchBar: Exit to dashboard")
        // Reset to main screen
        G1DisplayManager.shared.sendTextToG1("Dashboard")
    }
    
    private func handleLeftTouchBarTap() {
        // Implementation for left TouchBar functionality
        // In G1, this typically navigates dashboard or goes to previous page
        print("Left TouchBar: Dashboard navigation or page up")
    }
    
    private func handleRightTouchBarTap() {
        // Implementation for right TouchBar functionality
        // In G1, this typically handles QuickNote or goes to next page
        print("Right TouchBar: QuickNote or page down")
    }
}

// MARK: - G1SpeechDelegate

extension ContentView: G1SpeechDelegate {
    func didRecognizeText(_ text: String, isFinal: Bool) {
        print("Speech recognized: \(text) (final: \(isFinal))")
        
        if !isFinal {
            // Show real-time transcription on G1
            G1DisplayManager.shared.displayEvenAIStatus(.processing)
        }
    }
    
    func didReceiveLilyResponse(_ response: LilyResponse) {
        print("Lily response: \(response.text)")
        
        // Update G1 display with response
        G1DisplayManager.shared.updateLilyDisplay(
            emotion: response.emotion,
            message: response.text
        )
        
        // Show completion status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            G1DisplayManager.shared.displayEvenAIStatus(.complete)
        }
    }
    
    func didEncounterError(_ error: Error) {
        print("Speech recognition error: \(error)")
        
        // Show error on G1
        G1DisplayManager.shared.displayEvenAIStatus(.error("Spracherkennung fehlgeschlagen"))
        
        // Generate error response
        let errorResponse = LilyResponse(
            text: "Entschuldige, ich konnte dich nicht verstehen. Versuche es bitte nochmal.",
            emotion: .questioning
        )
        
        G1DisplayManager.shared.updateLilyDisplay(
            emotion: errorResponse.emotion,
            message: errorResponse.text
        )
    }
}

// MARK: - Speech Permission Extension

extension G1AudioManager {
    static func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
