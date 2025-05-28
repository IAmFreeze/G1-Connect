import SwiftUI
import Combine

class ContentViewModel: ObservableObject, G1TouchBarDelegate, G1SpeechDelegate {
    @Published var selectedTab = 0

    var bluetoothManager = BluetoothManager.shared
    var settingsManager = SettingsManager.shared
    private var g1AudioManager = G1AudioManager.shared
    private var lilyAIManager = LilyAIManager.shared

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupG1App()
    }

    func setupG1App() {
        print("Setting up G1 Connect App (ViewModel)...")
        bluetoothManager.touchBarDelegate = self
        g1AudioManager.speechDelegate = self

        if settingsManager.autoConnect, let lastDevice = UserDefaults.standard.string(forKey: "lastConnectedDevice") {
            print("Auto-connecting to last G1 device: \(lastDevice)")
            bluetoothManager.startScan()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.bluetoothManager.connectToDevice(deviceName: lastDevice)
            }
        }
        requestSpeechPermission()
        setupEvenAIListeners()
        print("G1 Connect App setup complete (ViewModel)")
    }

    func requestSpeechPermission() {
        G1AudioManager.requestSpeechPermission { granted in
            if granted {
                print("Speech recognition permission granted (ViewModel)")
            } else {
                print("Speech recognition permission denied (ViewModel)")
            }
        }
    }

    func setupEvenAIListeners() {
        NotificationCenter.default.publisher(for: .evenAIActivated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleEvenAIActivation() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .evenAIStopped)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleEvenAIStop() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .g1Connected)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleG1Connected() }
            .store(in: &cancellables)
    }

    func handleEvenAIActivation() {
        print("Even AI activated from G1 (ViewModel)")
        selectedTab = 0
        G1DisplayManager.shared.displayEvenAIStatus(.activated)
        g1AudioManager.startEvenAIProcessing()
        let activationResponse = lilyAIManager.generateRandomActivationResponse()
        G1DisplayManager.shared.updateLilyDisplay(
            emotion: activationResponse.emotion,
            message: activationResponse.text
        )
    }

    func handleEvenAIStop() {
        print("Even AI stopped from G1 (ViewModel)")
        g1AudioManager.stopEvenAIProcessing()
        G1DisplayManager.shared.displayEvenAIStatus(.complete)
    }

    func handleG1Connected() {
        print("G1 glasses connected (ViewModel)")
        settingsManager.sendAllSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            G1DisplayManager.shared.sendTestPattern()
        }
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

    // MARK: - G1TouchBarDelegate
    func didActivateEvenAI() {
        print("TouchBar: Even AI activated (ViewModel)")
        // Notification system will trigger handleEvenAIActivation
    }

    func didStopEvenAI() {
        print("TouchBar: Even AI stopped (ViewModel)")
        // Notification system will trigger handleEvenAIStop
    }

    func didTapTouchBar(side: TouchBarSide) {
        print("TouchBar tapped: \(side) (ViewModel)")
        switch side {
        case .left:
            handleLeftTouchBarTap()
        case .right:
            handleRightTouchBarTap()
        }
    }

    func didExitToDashboard() {
        print("TouchBar: Exit to dashboard (ViewModel)")
        G1DisplayManager.shared.sendTextToG1("Dashboard")
    }

    private func handleLeftTouchBarTap() {
        print("Left TouchBar: Dashboard navigation or page up (ViewModel)")
    }

    private func handleRightTouchBarTap() {
        print("Right TouchBar: QuickNote or page down (ViewModel)")
    }

    // MARK: - G1SpeechDelegate
    func didRecognizeText(_ text: String, isFinal: Bool) {
        print("Speech recognized: \(text) (final: \(isFinal)) (ViewModel)")
        if !isFinal {
            G1DisplayManager.shared.displayEvenAIStatus(.processing)
        }
    }

    func didReceiveLilyResponse(_ response: LilyResponse) {
        print("Lily response: \(response.text) (ViewModel)")
        G1DisplayManager.shared.updateLilyDisplay(
            emotion: response.emotion,
            message: response.text
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            G1DisplayManager.shared.displayEvenAIStatus(.complete)
        }
    }

    func didEncounterError(_ error: Error) {
        print("Speech recognition error: \(error) (ViewModel)")
        G1DisplayManager.shared.displayEvenAIStatus(.error("Spracherkennung fehlgeschlagen"))
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

// Assuming Notification.Name extensions like .evenAIActivated are defined elsewhere.
// Assuming G1TouchBarDelegate, G1SpeechDelegate, TouchBarSide, LilyResponse, G1DisplayManager, etc. are defined and accessible.
