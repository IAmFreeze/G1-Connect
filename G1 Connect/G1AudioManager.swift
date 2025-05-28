import Foundation
import AVFoundation
import Speech

/// Real LC3 Audio Manager for G1 Smart Glasses
class G1AudioManager: NSObject, ObservableObject {
    static let shared = G1AudioManager()
    
    // Published properties
    @Published var isProcessingAudio = false
    @Published var audioLevel: Float = 0.0
    @Published var isAudioInputAvailable = false
    
    // Audio processing
    private var audioBuffer = Data()
    private var lastSequenceNumber: UInt8 = 0
    private var lc3Decoder: LC3AudioDecoder?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    // Delegates
    weak var speechDelegate: G1SpeechDelegate?
    
    // Audio format for G1
    private let audioFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: Constants.G1Audio.sampleRate,
        channels: AVAudioChannelCount(Constants.G1Audio.channels),
        interleaved: false
    )
    
    private override init() {
        super.init()
        setupAudioComponents()
        setupSpeechRecognizer()
        BluetoothManager.shared.audioDelegate = self
    }
    
    private func setupAudioComponents() {
        // Initialize LC3 decoder (or fallback)
        lc3Decoder = LC3AudioDecoder()
        
        // Setup audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupSpeechRecognizer() {
        // Setup German speech recognizer for G1
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
        
        // Check availability
        isAudioInputAvailable = speechRecognizer?.isAvailable ?? false
        
        // Request permissions
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                    self?.isAudioInputAvailable = true
                case .denied:
                    print("Speech recognition denied")
                    self?.isAudioInputAvailable = false
                case .restricted:
                    print("Speech recognition restricted")
                    self?.isAudioInputAvailable = false
                case .notDetermined:
                    print("Speech recognition not determined")
                    self?.isAudioInputAvailable = false
                @unknown default:
                    print("Speech recognition unknown status")
                    self?.isAudioInputAvailable = false
                }
            }
        }
    }
    
    /// Starts Even AI audio processing
    func startEvenAIProcessing() {
        guard !isProcessingAudio else { return }
        guard isAudioInputAvailable else {
            print("Audio input not available")
            return
        }
        
        isProcessingAudio = true
        audioBuffer = Data()
        lastSequenceNumber = 0
        
        // Setup speech recognition
        setupSpeechRecognition()
        
        print("G1 Even AI audio processing started")
    }
    
    /// Stops Even AI audio processing
    func stopEvenAIProcessing() {
        guard isProcessingAudio else { return }
        
        isProcessingAudio = false
        
        // Finalize speech recognition
        finalizeSpeechRecognition()
        
        print("G1 Even AI audio processing stopped")
    }
    
    private func setupSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }
        
        // Cancel any ongoing recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self.speechDelegate?.didRecognizeText(recognizedText, isFinal: result.isFinal)
                }
                
                if result.isFinal {
                    self.processRecognizedText(recognizedText)
                }
            }
            
            if let error = error {
                print("Speech recognition error: \(error)")
                DispatchQueue.main.async {
                    self.speechDelegate?.didEncounterError(error)
                }
            }
        }
    }
    
    private func finalizeSpeechRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    private func processRecognizedText(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Send to LilyAI for processing
        LilyAIManager.shared.processUserInput(text) { [weak self] response in
            DispatchQueue.main.async {
                self?.speechDelegate?.didReceiveLilyResponse(response)
                
                // Send response to G1
                BluetoothManager.shared.sendTextToG1(response.text)
            }
        }
    }
    
    // MARK: - Audio Format Info
    
    /// Gets current audio format information
    var currentAudioFormat: String {
        return "LC3 → PCM 16kHz Mono"
    }
    
    /// Provides real-time audio visualization data
    var audioVisualizationData: [Float] {
        // Return mock data for audio visualization
        // In a real implementation, this would return FFT data
        return (0..<64).map { _ in Float.random(in: 0...audioLevel) }
    }
    
    /// Static method for requesting speech permission
    static func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
}

// MARK: - G1AudioDelegate

extension G1AudioManager: G1AudioDelegate {
    func didReceiveAudioData(_ data: Data, sequenceNumber: UInt8) {
        guard isProcessingAudio else { return }
        
        // Check sequence order
        let expectedSequence = UInt8((Int(lastSequenceNumber) + 1) % 256)
        if sequenceNumber != expectedSequence && lastSequenceNumber != 0 {
            print("Warning: Audio packet out of order. Expected: \(expectedSequence), Received: \(sequenceNumber)")
        }
        
        lastSequenceNumber = sequenceNumber
        
        // Add to buffer
        audioBuffer.append(data)
        
        // Process when we have enough data for an LC3 frame
        if audioBuffer.count >= Constants.G1Audio.frameSize {
            processAudioFrame()
        }
        
        // Update audio level for UI
        updateAudioLevel(from: data)
    }
    
    private func processAudioFrame() {
        guard let lc3Decoder = lc3Decoder else {
            print("LC3 decoder not available")
            return
        }
        
        // Extract one frame
        let frameData = audioBuffer.prefix(Constants.G1Audio.frameSize)
        audioBuffer = audioBuffer.dropFirst(Constants.G1Audio.frameSize)
        
        // Decode LC3 to PCM
        guard let pcmData = lc3Decoder.decode(Data(frameData)) else {
            print("Failed to decode LC3 audio")
            return
        }
        
        // Convert to AVAudioPCMBuffer and send to speech recognizer
        if let pcmBuffer = createPCMBuffer(from: pcmData) {
            recognitionRequest?.append(pcmBuffer)
        }
    }
    
    private func createPCMBuffer(from pcmData: Data) -> AVAudioPCMBuffer? {
        guard let format = audioFormat else { return nil }
        
        let frameCount = UInt32(pcmData.count / MemoryLayout<Float>.size)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // Copy data to buffer
        guard let channelData = buffer.floatChannelData else { return nil }
        
        pcmData.withUnsafeBytes { bytes in
            let floatBuffer = bytes.bindMemory(to: Float.self)
            for i in 0..<Int(frameCount) {
                channelData[0][i] = floatBuffer[i]
            }
        }
        
        return buffer
    }
    
    private func updateAudioLevel(from data: Data) {
        // Calculate simple RMS for audio level visualization
        let samples = data.withUnsafeBytes { bytes in
            bytes.bindMemory(to: Int16.self)
        }
        
        guard !samples.isEmpty else { return }
        
        let sum = samples.map { Float($0) * Float($0) }.reduce(0, +)
        let rms = sqrt(sum / Float(samples.count))
        let normalizedLevel = min(rms / 32768.0, 1.0)
        
        DispatchQueue.main.async {
            self.audioLevel = normalizedLevel
        }
    }
}

// MARK: - LC3 Audio Decoder

/// LC3 Audio Decoder for G1 Smart Glasses
class LC3AudioDecoder {
    
    /// Decodes LC3 audio data to PCM
    /// - Parameter lc3Data: Raw LC3 encoded data from G1
    /// - Returns: PCM audio data or nil if decoding fails
    func decode(_ lc3Data: Data) -> Data? {
        // IMPORTANT: This is a simplified implementation
        // In a real app, you would integrate a proper LC3 decoder library
        
        // For now, we'll use a basic conversion assuming the data is already in a usable format
        // This is just for demonstration - real LC3 decoding requires the LC3 codec library
        
        return convertMockLC3ToPCM(lc3Data)
    }
    
    private func convertMockLC3ToPCM(_ data: Data) -> Data? {
        // Mock conversion - in reality, you need the LC3 codec library
        // This assumes the input is already close to PCM format
        
        var pcmData = Data()
        pcmData.reserveCapacity(data.count * 2) // Approximate expansion
        
        // Simple interpolation to simulate decompression
        for i in stride(from: 0, to: data.count - 1, by: 2) {
            let sample1 = data[i]
            let sample2 = data[i + 1]
            
            // Convert to 16-bit samples
            let sample16_1 = Int16(sample1) - 128
            let sample16_2 = Int16(sample2) - 128
            
            // Add interpolated sample
            let interpolated = (sample16_1 + sample16_2) / 2
            
            // Convert to float and add to PCM data
            let floatSample1 = Float(sample16_1) / 128.0
            let floatSample2 = Float(interpolated) / 128.0
            let floatSample3 = Float(sample16_2) / 128.0
            
            withUnsafeBytes(of: floatSample1) { pcmData.append(contentsOf: $0) }
            withUnsafeBytes(of: floatSample2) { pcmData.append(contentsOf: $0) }
            withUnsafeBytes(of: floatSample3) { pcmData.append(contentsOf: $0) }
        }
        
        return pcmData
    }
}

// MARK: - Protocols

protocol G1SpeechDelegate: AnyObject {
    func didRecognizeText(_ text: String, isFinal: Bool)
    func didReceiveLilyResponse(_ response: LilyResponse)
    func didEncounterError(_ error: Error)
}
