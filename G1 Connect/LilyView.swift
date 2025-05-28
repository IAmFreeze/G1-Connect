import SwiftUI

struct LilyView: View {
    @StateObject internal var lilyViewModel = LilyViewModel()
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var g1AudioManager = G1AudioManager.shared
    @StateObject private var lilyAIManager = LilyAIManager.shared
    @State private var userInput = ""
    @State internal var showingInput = false
    @State private var showingConversationHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // G1 Connection Status Banner
                if bluetoothManager.isConnected {
                    G1ConnectionBanner()
                        .transition(.slide)
                }
                
                // Main Lily Interface
                HStack(spacing: 20) {
                    // Lily Avatar Panel
                    LilyAvatarPanel(
                        emotion: lilyViewModel.currentEmotion,
                        emotionImage: lilyViewModel.currentEmotionImage,
                        isAnimating: g1AudioManager.isProcessingAudio
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.4)
                    
                    // Message Panel
                    LilyMessagePanel(
                        message: lilyViewModel.currentMessage,
                        isProcessing: lilyAIManager.isProcessing,
                        audioLevel: g1AudioManager.audioLevel
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Controls Section
                VStack(spacing: 16) {
                    // Even AI Status
                    if g1AudioManager.isProcessingAudio {
                        EvenAIStatusView()
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Input Area
                    if showingInput {
                        LilyInputView(
                            userInput: $userInput,
                            onSubmit: processUserInput,
                            onCancel: { showingInput = false }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Action Buttons
                    LilyActionButtons(
                        showingInput: $showingInput,
                        showingHistory: $showingConversationHistory,
                        onRandomResponse: generateRandomResponse,
                        onTestG1: sendTestToG1,
                        isConnected: bluetoothManager.isConnected
                    )
                }
                .padding(.horizontal)
                
                // Bottom Status
                LilyStatusBar(
                    connectionStatus: bluetoothManager.connectionStatus,
                    isConnected: bluetoothManager.isConnected,
                    isRecording: bluetoothManager.isRecording
                )
            }
            .background(Constants.backgroundColor.ignoresSafeArea())
            .navigationTitle("Lily")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Historie") {
                        showingConversationHistory.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingConversationHistory) {
                ConversationHistoryView()
            }
            .onTapGesture {
                if !showingInput && !g1AudioManager.isProcessingAudio {
                    generateRandomResponse()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingInput)
            .animation(.easeInOut(duration: 0.3), value: g1AudioManager.isProcessingAudio)
        }
    }
    
    private func processUserInput() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let inputText = userInput
        userInput = ""
        showingInput = false
        
        // Process with Lily AI
        lilyAIManager.processUserInput(inputText) { response in
            lilyViewModel.setResponse(response)
            
            // Send to G1 if connected
            if bluetoothManager.isConnected {
                G1DisplayManager.shared.updateLilyDisplay(
                    emotion: response.emotion,
                    message: response.text
                )
            }
        }
    }
    
    private func generateRandomResponse() {
        let randomResponse = lilyAIManager.generateRandomActivationResponse()
        lilyViewModel.setResponse(randomResponse)
        
        if bluetoothManager.isConnected {
            G1DisplayManager.shared.updateLilyDisplay(
                emotion: randomResponse.emotion,
                message: randomResponse.text
            )
        }
    }
    
    private func sendTestToG1() {
        guard bluetoothManager.isConnected else { return }
        
        G1DisplayManager.shared.sendTestPattern()
        
        let testResponse = LilyResponse(
            text: "G1 Test-Muster gesendet! Siehst du das Gitter-Muster auf deiner Brille?",
            emotion: .questioning
        )
        
        lilyViewModel.setResponse(testResponse)
    }
}

// MARK: - Supporting Views

struct G1ConnectionBanner: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "eyeglasses")
                .foregroundColor(Constants.successColor)
            
            Text("G1 Brille verbunden")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if bluetoothManager.isRecording {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Constants.errorColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(bluetoothManager.isRecording ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: bluetoothManager.isRecording)
                    
                    Text("Aufnahme")
                        .font(.caption)
                        .foregroundColor(Constants.errorColor)
                }
            }
        }
        .padding()
        .background(Constants.secondaryBackgroundColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LilyAvatarPanel: View {
    let emotion: LilyEmotion
    let emotionImage: UIImage?
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.secondaryBackgroundColor)
                .shadow(color: isAnimating ? Constants.primaryColor.opacity(0.5) : .clear, radius: 10)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            
            if let image = emotionImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isAnimating)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: getSystemImageForEmotion(emotion))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Constants.primaryColor)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isAnimating)
                    
                    Text(emotion.displayName)
                        .font(.caption)
                        .foregroundColor(Constants.secondaryTextColor)
                }
                .padding(20)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
    
    private func getSystemImageForEmotion(_ emotion: LilyEmotion) -> String {
        switch emotion {
        case .happy: return "face.smiling"
        case .cheerful: return "face.smiling.inverse"
        case .thoughtful: return "brain.head.profile"
        case .serious: return "face.dashed"
        case .surprised: return "exclamationmark.circle"
        case .questioning: return "questionmark.circle"
        }
    }
}

struct LilyMessagePanel: View {
    let message: String
    let isProcessing: Bool
    let audioLevel: Float
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.secondaryBackgroundColor)
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 12) {
                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Lily denkt nach...")
                            .font(.caption)
                            .foregroundColor(Constants.secondaryTextColor)
                    }
                }
                
                ScrollView {
                    Text(message)
                        .foregroundColor(Constants.textColor)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if audioLevel > 0 {
                    AudioVisualizationView(level: audioLevel)
                        .frame(height: 20)
                }
            }
            .padding()
        }
    }
}

struct AudioVisualizationView: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(level > Float(index) / 20.0 ? Constants.primaryColor : Constants.secondaryTextColor.opacity(0.3))
                    .frame(width: 3)
                    .scaleEffect(y: level > Float(index) / 20.0 ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
}

struct EvenAIStatusView: View {
    @StateObject private var g1AudioManager = G1AudioManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(Constants.errorColor)
                    .scaleEffect(1.2)
                
                Text("Even AI aktiv")
                    .font(.headline)
                    .foregroundColor(Constants.textColor)
                
                Spacer()
                
                Text("Spreche jetzt...")
                    .font(.caption)
                    .foregroundColor(Constants.secondaryTextColor)
            }
            
            AudioVisualizationView(level: g1AudioManager.audioLevel)
                .frame(height: 30)
        }
        .padding()
        .background(Constants.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct LilyInputView: View {
    @Binding var userInput: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Frage Lily etwas...", text: $userInput, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .onSubmit(onSubmit)
                
                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Constants.primaryColor)
                        .clipShape(Circle())
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Button("Abbrechen", action: onCancel)
                .font(.caption)
                .foregroundColor(Constants.secondaryTextColor)
        }
    }
}

struct LilyActionButtons: View {
    @Binding var showingInput: Bool
    @Binding var showingHistory: Bool
    let onRandomResponse: () -> Void
    let onTestG1: () -> Void
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: { showingInput.toggle() }) {
                    HStack {
                        Image(systemName: showingInput ? "keyboard.chevron.compact.down" : "keyboard")
                        Text(showingInput ? "Eingabe verbergen" : "Mit Lily sprechen")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Constants.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: onRandomResponse) {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Zufällig")
                    }
                    .padding()
                    .background(Constants.secondaryBackgroundColor)
                    .foregroundColor(Constants.textColor)
                    .cornerRadius(12)
                }
            }
            
            if isConnected {
                Button(action: onTestG1) {
                    HStack {
                        Image(systemName: "eyeglasses")
                        Text("G1 Test senden")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Constants.successColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct LilyStatusBar: View {
    let connectionStatus: String
    let isConnected: Bool
    let isRecording: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Constants.successColor : Constants.errorColor)
                .frame(width: 8, height: 8)
            
            Text(connectionStatus)
                .font(.caption)
                .foregroundColor(Constants.secondaryTextColor)
            
            Spacer()
            
            if isRecording {
                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(Constants.errorColor)
                        .font(.caption)
                    
                    Text("REC")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Constants.errorColor)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

struct ConversationHistoryView: View {
    @StateObject private var lilyAIManager = LilyAIManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Unterhaltungsverlauf") {
                    if lilyAIManager.currentContext.isEmpty {
                        Text("Noch keine Unterhaltung gestartet")
                            .foregroundColor(Constants.secondaryTextColor)
                            .italic()
                    } else {
                        ForEach(Array(lilyAIManager.currentContext.enumerated()), id: \.offset) { index, message in
                            ConversationEntryView(message: message, isUser: message.hasPrefix("Du:"))
                        }
                    }
                }
                
                Section("Statistiken") {
                    let stats = lilyAIManager.conversationStats
                    
                    HStack {
                        Text("Nachrichten gesamt")
                        Spacer()
                        Text("\(stats.totalMessages)")
                            .foregroundColor(Constants.primaryColor)
                    }
                    
                    HStack {
                        Text("Deine Nachrichten")
                        Spacer()
                        Text("\(stats.userMessages)")
                            .foregroundColor(Constants.primaryColor)
                    }
                    
                    HStack {
                        Text("Lily's Antworten")
                        Spacer()
                        Text("\(stats.assistantMessages)")
                            .foregroundColor(Constants.primaryColor)
                    }
                    
                    HStack {
                        Text("⌀ Wörter pro Nachricht")
                        Spacer()
                        Text(String(format: "%.1f", stats.averageWordsPerMessage))
                            .foregroundColor(Constants.primaryColor)
                    }
                }
            }
            .navigationTitle("Gesprächsverlauf")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Löschen") {
                        lilyAIManager.clearConversationHistory()
                    }
                    .foregroundColor(Constants.errorColor)
                }
            }
        }
    }
}

struct ConversationEntryView: View {
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isUser ? "person.circle" : "brain.head.profile")
                .foregroundColor(isUser ? Constants.primaryColor : Constants.successColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isUser ? "Du" : "Lily")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isUser ? Constants.primaryColor : Constants.successColor)
                
                Text(message.dropFirst(message.firstIndex(of: ":").map { message.distance(from: message.startIndex, to: $0) + 2 } ?? 0))
                    .foregroundColor(Constants.textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - LilyViewModel (Enhanced)

class LilyViewModel: ObservableObject {
    @Published var currentEmotion: LilyEmotion = .happy
    @Published var currentMessage: String = "Hallo! Ich bin Lily, deine persönliche Assistentin für die G1-Brille. Du kannst mich mit \"Hey, Lily\" aktivieren oder die TouchBar drücken, um mit mir zu sprechen."
    @Published var currentEmotionImage: UIImage?
    
    private var emotionImages: [LilyEmotion: UIImage] = [:]
    
    init() {
        loadEmotionImages()
    }
    
    private func loadEmotionImages() {
        for emotion in LilyEmotion.allCases {
            if let image = UIImage(named: emotion.imageName) {
                emotionImages[emotion] = image
            }
        }
        
        // Set initial image
        updateEmotionImage()
    }
    
    func setEmotion(_ emotion: LilyEmotion) {
        currentEmotion = emotion
        updateEmotionImage()
    }
    
    func setResponse(_ response: LilyResponse) {
        currentMessage = response.text
        setEmotion(response.emotion)
    }
    
    private func updateEmotionImage() {
        currentEmotionImage = emotionImages[currentEmotion]
    }
    
    func generateRandomResponse() {
        let response = LilyAIManager.shared.generateRandomActivationResponse()
        setResponse(response)
    }
}

struct LilyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LilyView()
        }
        .preferredColorScheme(.dark)
    }
}
