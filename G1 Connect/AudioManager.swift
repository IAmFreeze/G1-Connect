import Foundation
import AVFoundation
import Speech

/// Manager für die Audioverarbeitung von der G1-Brille
class AudioManager {
    static let shared = AudioManager()
    
    // Delegate für Spracherkennungsergebnisse
    weak var speechDelegate: SpeechRecognitionDelegate?
    
    // LC3-Decoder für Brillen-Audio
    private var lc3Decoder: LC3Decoder?
    
    // Audio-Buffer für eingehende Daten
    private var audioBuffer = Data()
    
    // Sequenznummer für die Paketordnung
    private var lastSequenceNumber: UInt8 = 0
    
    private init() {
        setupLC3Decoder()
        print("AudioManager initialisiert")
    }
    
    /// Richtet den LC3-Decoder ein
    private func setupLC3Decoder() {
        // In einer realen Implementierung würde hier der LC3-Decoder initialisiert
        // Da dies eine Beispielimplementierung ist, verwenden wir einen Platzhalter
        lc3Decoder = LC3Decoder()
    }
    
    /// Verarbeitet Audiodaten von der Brille
    func processAudioFromGlasses(_ audioData: Data, sequenceNumber: UInt8) {
        // Prüfen, ob die Sequenznummer in der richtigen Reihenfolge ist
        let expectedSequenceNumber = UInt8((Int(lastSequenceNumber) + 1) % 256) // Cast to Int for calculation, then back to UInt8

        if sequenceNumber != expectedSequenceNumber && lastSequenceNumber != 0 {
            print("Warnung: Audiopaket außer Reihenfolge empfangen. Erwartet: \(expectedSequenceNumber), Erhalten: \(sequenceNumber)")
        }
            
        lastSequenceNumber = sequenceNumber
            
        // Audiodaten zum Buffer hinzufügen
        audioBuffer.append(audioData)
            
        // Wenn genügend Daten für eine Dekodierung vorhanden sind, dekodieren
        if audioBuffer.count >= 240 { // Annahme: 240 Bytes für einen LC3-Frame
            decodeAndProcessAudio()
        }
    }
    
    /// Dekodiert und verarbeitet die gepufferten Audiodaten
    private func decodeAndProcessAudio() {
        guard let decoder = lc3Decoder else {
            print("Fehler: LC3-Decoder nicht initialisiert")
            return
        }
        
        // LC3-Daten in PCM konvertieren
        guard let pcmData = decoder.decodeToPCM(audioBuffer) else {
            print("Fehler bei der LC3-Dekodierung")
            return
        }
        
        // Buffer zurücksetzen
        audioBuffer = Data()
        
        // PCM-Daten an den SpeechRecognizer weiterleiten
        SpeechRecognizer.shared.processAudioBuffer(pcmData)
    }
}

/// Protokoll für Spracherkennungsergebnisse
protocol SpeechRecognitionDelegate: AnyObject {
    func didRecognizeText(_ text: String)
    func didDetectWakeWord()
}

/// Platzhalter für LC3-Decoder
class LC3Decoder {
    func decodeToPCM(_ lc3Data: Data) -> Data? {
        // In einer realen Implementierung würde hier die LC3-Dekodierung stattfinden
        // Dies ist ein Platzhalter, der einfach die Daten zurückgibt
        return lc3Data
    }
}

// Erweiterung des SpeechRecognizer für die Brillen-Integration
extension SpeechRecognizer {
    
    /// Verarbeitet einen Audio-Buffer von der Brille
    func processAudioBuffer(_ audioBuffer: Data) {
        // Audio-Format für den Buffer erstellen
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                  sampleRate: 16000,
                                  channels: 1,
                                  interleaved: false)
        
        guard let format = format else {
            print("Fehler beim Erstellen des Audio-Formats")
            return
        }
        
        // PCM-Buffer erstellen
        let frameCount = UInt32(audioBuffer.count) / 4 // 4 Bytes pro Float32
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Fehler beim Erstellen des PCM-Buffers")
            return
        }
        
        // Daten in den Buffer kopieren
        if let floatChannelData = pcmBuffer.floatChannelData {
            audioBuffer.withUnsafeBytes { bufferPointer in
                let floatBuffer = bufferPointer.bindMemory(to: Float.self)
                for i in 0..<Int(frameCount) {
                    floatChannelData[0][i] = floatBuffer[i]
                }
            }
        }
        
        pcmBuffer.frameLength = frameCount
        
        // Buffer an den Recognizer übergeben
        recognitionRequest?.append(pcmBuffer)
    }
    
    /// Startet die Spracherkennung mit Audio von der Brille
    func startListeningFromGlasses(for wakeWord: String, wakeWordDetected: @escaping () -> Void) {
        self.wakeWord = wakeWord.lowercased()
        self.wakeWordDetectedHandler = wakeWordDetected
        self.isListening = true
        
        // Bestehende Tasks abbrechen
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Recognition Request erstellen
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Recognition Task starten
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Erkannten Text aktualisieren
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                
                // Nach Wake-Word suchen
                let transcription = result.bestTranscription.formattedString.lowercased()
                if transcription.contains(self.wakeWord?.lowercased() ?? "") {
                    DispatchQueue.main.async {
                        self.wakeWordDetectedHandler?()
                        self.onActivationDetected?()
                    }
                    
                    // Recognition nach Wake-Word-Erkennung zurücksetzen
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    
                    // Nach kurzer Pause neu starten
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if let wakeWord = self.wakeWord, let handler = self.wakeWordDetectedHandler {
                            self.startListeningFromGlasses(for: wakeWord, wakeWordDetected: handler)
                        }
                    }
                    return
                }
                
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Recognition zurücksetzen und neu starten
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                // Neu starten
                if let wakeWord = self.wakeWord, let handler = self.wakeWordDetectedHandler {
                    self.startListeningFromGlasses(for: wakeWord, wakeWordDetected: handler)
                }
            }
        }
    }
}
