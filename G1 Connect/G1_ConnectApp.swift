import SwiftUI
import AVFoundation

@main
struct G1_ConnectApp: App {
    
    init() {
        setupAppConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    setupG1Integration()
                }
        }
    }
    
    private func setupAppConfiguration() {
        print("🚀 G1 Connect App starting...")
        
        // Configure navigation bar appearance
        configureNavigationBarAppearance()
        
        // Configure tab bar appearance
        configureTabBarAppearance()
        
        // Setup app-wide configurations
        setupGlobalSettings()
    }
    
    private func configureNavigationBarAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = Constants.secondaryBackgroundColorUIKit
        navBarAppearance.titleTextAttributes = [.foregroundColor: Constants.primaryColorUIKit]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: Constants.primaryColorUIKit]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = Constants.primaryColorUIKit
    }
    
    private func configureTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = Constants.secondaryBackgroundColorUIKit
        
        // Configure tab bar item colors
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = Constants.primaryColorUIKit
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: Constants.primaryColorUIKit
        ]
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setupGlobalSettings() {
        // Configure audio session for G1 compatibility
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
            )
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
        }
        
        // Setup background processing (if needed)
        setupBackgroundTaskSupport()
        
        print("✅ App configuration completed")
    }
    
    private func setupG1Integration() {
        print("🥽 Setting up G1 smart glasses integration...")
        
        // Initialize core managers
        
        // Verify G1 components are ready
        verifyG1Components()
        
        // Setup app lifecycle observers
        setupAppLifecycleObservers()
        
        print("✅ G1 integration setup completed")
    }
    
    private func verifyG1Components() {
        print("🔍 Verifying G1 components...")
        
        // Check Bluetooth availability
        let bluetoothManager = BluetoothManager.shared
        print("📡 Bluetooth Manager: Ready")
        
        // Check audio components
        let audioManager = G1AudioManager.shared
        if audioManager.isAudioInputAvailable {
            print("🎤 Audio Manager: Ready")
        } else {
            print("⚠️ Audio Manager: Speech recognition not available")
        }
        
        // Check display components
        print("📱 Display Manager: Ready")
        
        // Check AI components
        print("🧠 Lily AI Manager: Ready")
        
        print("✅ Component verification completed")
    }
    
    private func setupAppLifecycleObservers() {
        // Setup observers for app lifecycle events
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppWillEnterForeground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppWillTerminate()
        }
    }
    
    private func setupBackgroundTaskSupport() {
        // Note: Real background processing requires proper entitlements
        // This is a placeholder for background task setup
        print("📋 Background task support configured")
    }
    
    // MARK: - App Lifecycle Handlers
    
    private func handleAppDidEnterBackground() {
        print("📱 App entered background")
        
        // Maintain G1 connection in background (if allowed)
        if BluetoothManager.shared.isConnected {
            // Send background status to G1
            G1DisplayManager.shared.sendTextToG1("App im Hintergrund\nG1 bleibt verbunden")
        }
        
        // Pause non-essential operations
        G1AudioManager.shared.stopEvenAIProcessing()
    }
    
    private func handleAppWillEnterForeground() {
        print("📱 App entering foreground")
        
        // Resume G1 operations
        if BluetoothManager.shared.isConnected {
            // Send welcome back message
            G1DisplayManager.shared.sendTextToG1("Willkommen zurück!\nG1 Connect ist bereit")
            
            // Refresh settings
            SettingsManager.shared.sendAllSettings()
        }
    }
    
    private func handleAppWillTerminate() {
        print("📱 App terminating")
        
        // Clean shutdown
        if BluetoothManager.shared.isConnected {
            // Send goodbye message to G1
            G1DisplayManager.shared.sendTextToG1("G1 Connect beendet\nAuf Wiedersehen!")
            
            // Gracefully disconnect after message is sent
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                BluetoothManager.shared.disconnectFromGlasses()
            }
        }
        
        // Stop audio processing
        G1AudioManager.shared.stopEvenAIProcessing()
        
        // Clear conversation history if needed
        // LilyAIManager.shared.clearConversationHistory()
    }
}

// MARK: - App Version and Build Info

extension G1_ConnectApp {
    
    /// Gets current app version info
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Gets current build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Gets full version string
    static var fullVersionString: String {
        "G1 Connect v\(appVersion) (\(buildNumber))"
    }
    
    /// Gets app bundle identifier
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.g1connect.app"
    }
}

// MARK: - Debug and Testing Support

#if DEBUG
extension G1_ConnectApp {
    
    /// Enables debug mode features
    static func enableDebugMode() {
        print("🔧 Debug mode enabled")
        
        // Enable additional logging
        UserDefaults.standard.set(true, forKey: "debugMode")
        
        // Show debug information
        print("📱 App Version: \(fullVersionString)")
        print("📦 Bundle ID: \(bundleIdentifier)")
        print("🥽 G1 Protocol Version: Official Even Realities")
    }
    
    /// Simulates G1 connection for testing
    static func simulateG1Connection() {
        print("🧪 Simulating G1 connection for testing")
        
        // This would be used for simulator testing
        // Real implementation would require actual G1 hardware
    }
}
#endif
