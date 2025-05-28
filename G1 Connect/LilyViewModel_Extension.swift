import Foundation
import UIKit
import SwiftUI

// Erweiterung des LilyViewModel für die Brillen-Integration
extension LilyViewModel {
    
    /// Aktualisiert die Brillenanzeige mit dem aktuellen Zustand
    func updateGlassesDisplay() {
        if BluetoothManager.shared.isConnected {
            // Character Box mit aktuellem Emotions-Bild aktualisieren
            if let image = currentEmotionImage {
                BrilleDisplayManager.shared.sendCharacterImage(image)
            }
            
            // Context Box mit aktuellem Text aktualisieren
            BrilleDisplayManager.shared.sendContextText(currentMessage)
        }
    }
    
    /// Überschreibt die bestehende setResponse-Methode, um auch die Brille zu aktualisieren
    func setResponseWithGlassesUpdate(_ response: LilyResponse) {
        // Bestehende Funktionalität beibehalten
        currentMessage = response.text
        setEmotion(response.emotion)
        
        // Brillenanzeige aktualisieren
        updateGlassesDisplay()
    }
    
    /// Generiert eine zufällige Antwort und aktualisiert die Brille
    func generateRandomResponseWithGlassesUpdate() {
        // Bestehende Funktionalität für zufällige Antworten nutzen
        let responses = [
            LilyResponse(text: "Ich kann dir mit verschiedenen Aufgaben helfen. Möchtest du das Wetter wissen, einen Timer stellen oder eine Erinnerung erstellen?", emotion: .cheerful),
            LilyResponse(text: "Hmm, lass mich darüber nachdenken... Das ist eine interessante Frage.", emotion: .thoughtful),
            LilyResponse(text: "Ich habe diese Information für dich gefunden. Möchtest du mehr Details dazu?", emotion: .happy),
            LilyResponse(text: "Es tut mir leid, aber ich kann diese Anfrage im Moment nicht verarbeiten. Könntest du es anders formulieren?", emotion: .serious),
            LilyResponse(text: "Oh! Das ist überraschend. Ich habe etwas Neues gelernt.", emotion: .surprised),
            LilyResponse(text: "Ich bin nicht sicher, ob ich dich richtig verstanden habe. Könntest du das bitte näher erläutern?", emotion: .questioning)
        ]
        
        let randomResponse = responses.randomElement()!
        setResponseWithGlassesUpdate(randomResponse)
    }
    
    /// Verarbeitet Benutzereingaben und aktualisiert die Brille
    func processUserInputWithGlassesUpdate(_ input: String) {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let response = LilyResponse.processInput(input)
        setResponseWithGlassesUpdate(response)
    }
}
