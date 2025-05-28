import Foundation
import SwiftUI
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    static let shared = SpeechRecognizer()
    
    @Published var isListening = false
    @Published var recognizedText = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var wakeWord: String?
    private var wakeWordDetectedHandler: (() -> Void)?
    
    // For UIKit compatibility
    var onActivationDetected: (() -> Void)?
    
    private init() {}
    
    func startListening(for wakeWord: String, wakeWordDetected: @escaping () -> Void) {
        self.wakeWord = wakeWord.lowercased()
        self.wakeWordDetectedHandler = wakeWordDetected
        self.isListening = true
        
        // Cancel any ongoing task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        
        // Configure input node
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Update recognized text
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                
                // Check for wake word
                let transcription = result.bestTranscription.formattedString.lowercased()
                if transcription.contains(self.wakeWord?.lowercased() ?? "") {
                    DispatchQueue.main.async {
                        self.wakeWordDetectedHandler?()
                        self.onActivationDetected?()
                    }
                    
                    // Reset recognition after wake word detection
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    // Restart listening after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if let wakeWord = self.wakeWord, let handler = self.wakeWordDetectedHandler {
                            self.startListening(for: wakeWord, wakeWordDetected: handler)
                        }
                    }
                    return
                }
                
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop audio engine and restart listening
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                // Restart listening
                if let wakeWord = self.wakeWord, let handler = self.wakeWordDetectedHandler {
                    self.startListening(for: wakeWord, wakeWordDetected: handler)
                }
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }
    
    func stopListening() {
        isListening = false
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
    }
    
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
}
