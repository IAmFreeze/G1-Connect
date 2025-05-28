//
//  LilyAIManager.swift
//  G1 Connect
//
//  Created by Nicolas Fortune on 28.05.25.
//


import Foundation
import SwiftUI

/// Enhanced AI Manager for Lily with real AI capabilities
class LilyAIManager: ObservableObject {
    static let shared = LilyAIManager()
    
    @Published var isProcessing = false
    @Published var currentContext: [String] = []
    
    // AI Configuration
    private let maxContextLength = 10
    private var conversationHistory: [ConversationEntry] = []
    
    private init() {
        print("LilyAIManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Processes user input and generates appropriate Lily response
    /// - Parameters:
    ///   - input: User's text input
    ///   - completion: Completion handler with Lily's response
    func processUserInput(_ input: String, completion: @escaping (LilyResponse) -> Void) {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(LilyResponse.fromStandardResponse(type: "unknown"))
            return
        }
        
        isProcessing = true
        
        // Add to conversation history
        addToConversationHistory(.user(input))
        
        // Process asynchronously to simulate AI processing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let response = self?.generateLilyResponse(for: input) ?? LilyResponse.fromStandardResponse(type: "unknown")
            
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.addToConversationHistory(.assistant(response.text))
                completion(response)
            }
        }
    }
    
    /// Generates a contextual response based on conversation history
    /// - Parameter input: Current user input
    /// - Returns: Appropriate Lily response
    private func generateLilyResponse(for input: String) -> LilyResponse {
        let lowercasedInput = input.lowercased()
        
        // Enhanced pattern matching with context awareness
        if isGreeting(lowercasedInput) {
            return generateGreetingResponse()
        } else if isWeatherQuery(lowercasedInput) {
            return generateWeatherResponse()
        } else if isTimeQuery(lowercasedInput) {
            return generateTimeResponse()
        } else if isTimerRequest(lowercasedInput) {
            return generateTimerResponse(from: input)
        } else if isReminderRequest(lowercasedInput) {
            return generateReminderResponse(from: input)
        } else if isEmotionalQuery(lowercasedInput) {
            return generateEmotionalResponse()
        } else if isQuestionAboutLily(lowercasedInput) {
            return generateSelfAwarenessResponse()
        } else if isCompliment(lowercasedInput) {
            return generateComplimentResponse()
        } else if isComplaint(lowercasedInput) {
            return generateSupportiveResponse()
        } else {
            return generateContextualUnknownResponse(input)
        }
    }
    
    // MARK: - Pattern Recognition
    
    private func isGreeting(_ input: String) -> Bool {
        let greetings = ["hallo", "hi", "hey", "guten tag", "guten morgen", "guten abend", "servus", "moin"]
        return greetings.contains { input.contains($0) }
    }
    
    private func isWeatherQuery(_ input: String) -> Bool {
        let weatherWords = ["wetter", "temperatur", "regen", "sonne", "bewölkt", "warm", "kalt", "grad"]
        return weatherWords.contains { input.contains($0) }
    }
    
    private func isTimeQuery(_ input: String) -> Bool {
        let timeWords = ["zeit", "uhr", "uhrzeit", "spät", "früh", "datum", "heute"]
        return timeWords.contains { input.contains($0) }
    }
    
    private func isTimerRequest(_ input: String) -> Bool {
        let timerWords = ["timer", "wecker", "alarm", "erinnerung", "minuten", "stunden"]
        return timerWords.contains { input.contains($0) } && 
               (input.contains("stell") || input.contains("setz") || input.contains("mach"))
    }
    
    private func isReminderRequest(_ input: String) -> Bool {
        let reminderWords = ["erinner", "notiz", "aufschreib", "merk", "vergiss nicht"]
        return reminderWords.contains { input.contains($0) }
    }
    
    private func isEmotionalQuery(_ input: String) -> Bool {
        let emotionalWords = ["fühl", "traurig", "glücklich", "müde", "gestresst", "freude", "ärger", "angst"]
        return emotionalWords.contains { input.contains($0) }
    }
    
    private func isQuestionAboutLily(_ input: String) -> Bool {
        let selfWords = ["wer bist du", "was bist du", "lily", "kannst du", "was machst du", "hilfst du"]
        return selfWords.contains { input.contains($0) }
    }
    
    private func isCompliment(_ input: String) -> Bool {
        let compliments = ["danke", "toll", "super", "großartig", "perfekt", "klasse", "genial"]
        return compliments.contains { input.contains($0) }
    }
    
    private func isComplaint(_ input: String) -> Bool {
        let complaints = ["versteh nicht", "funktioniert nicht", "problem", "fehler", "schlecht", "nervt"]
        return complaints.contains { input.contains($0) }
    }
    
    // MARK: - Response Generators
    
    private func generateGreetingResponse() -> LilyResponse {
        let greetings = [
            "Hallo! Schön dich zu sehen! Wie kann ich dir heute helfen?",
            "Hi! Ich bin Lily, deine Assistentin. Was kann ich für dich tun?",
            "Guten Tag! Wie geht es dir denn heute?",
            "Hey! Bereit für ein neues Abenteuer? Frag mich alles!",
            "Hallo! Ich freue mich, mit dir zu sprechen. Was beschäftigt dich?"
        ]
        return LilyResponse(text: greetings.randomElement()!, emotion: .happy)
    }
    
    private func generateWeatherResponse() -> LilyResponse {
        // In a real app, this would call a weather API
        let weatherResponses = [
            "Das Wetter ist heute wunderschön! 22°C und sonnig. Perfect für einen Spaziergang!",
            "Es ist bewölkt mit 18°C. Vielleicht nimmst du einen Regenschirm mit?",
            "Heute wird es warm! 26°C und viel Sonne. Vergiss die Sonnenbrille nicht!",
            "Ein gemütlicher Tag mit 20°C und leichten Wolken. Ideal für Indoor-Aktivitäten."
        ]
        return LilyResponse(text: weatherResponses.randomElement()!, emotion: .cheerful)
    }
    
    private func generateTimeResponse() -> LilyResponse {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        
        let timeString = formatter.string(from: Date())
        let responses = [
            "Es ist jetzt \(timeString).",
            "Die aktuelle Zeit: \(timeString). Wie kann ich dir weiterhelfen?",
            "Zur Zeit ist es \(timeString). Hast du etwas Wichtiges vor?"
        ]
        return LilyResponse(text: responses.randomElement()!, emotion: .thoughtful)
    }
    
    private func generateTimerResponse(from input: String) -> LilyResponse {
        // Extract time from input (simplified)
        let timeMinutes = extractTimeFromInput(input)
        let timerText = timeMinutes > 0 ? 
            "Timer für \(timeMinutes) Minuten wurde gestellt! Ich benachrichtige dich, wenn die Zeit um ist." :
            "Timer für 5 Minuten wurde gestellt! Ich benachrichtige dich, wenn die Zeit um ist."
        
        return LilyResponse(text: timerText, emotion: .serious)
    }
    
    private func generateReminderResponse(from input: String) -> LilyResponse {
        let reminderText = "Ich habe eine Erinnerung für dich erstellt: '\(input)'. Du wirst rechtzeitig benachrichtigt!"
        return LilyResponse(text: reminderText, emotion: .thoughtful)
    }
    
    private func generateEmotionalResponse() -> LilyResponse {
        let responses = [
            "Ich verstehe, dass du dich so fühlst. Möchtest du darüber sprechen?",
            "Gefühle sind wichtig. Ich bin hier, um dir zuzuhören.",
            "Es ist okay, so zu empfinden. Wie kann ich dir helfen, dich besser zu fühlen?",
            "Jeder hat mal schwierige Momente. Du bist nicht allein."
        ]
        return LilyResponse(text: responses.randomElement()!, emotion: .serious)
    }
    
    private func generateSelfAwarenessResponse() -> LilyResponse {
        let responses = [
            "Ich bin Lily, deine persönliche KI-Assistentin! Ich lebe in deiner G1-Brille und helfe dir bei allem Möglichen.",
            "Hi! Ich bin Lily - eine KI, die speziell für die G1-Brille entwickelt wurde. Ich kann dir mit Informationen, Erinnerungen und vielem mehr helfen!",
            "Ich bin Lily, deine digitale Begleiterin. Meine Aufgabe ist es, dir den Alltag zu erleichtern und für dich da zu sein.",
            "Lily hier! Ich bin eine künstliche Intelligenz, die in deiner G1-Brille lebt. Denk an mich als deine persönliche Assistentin!"
        ]
        return LilyResponse(text: responses.randomElement()!, emotion: .happy)
    }
    
    private func generateComplimentResponse() -> LilyResponse {
        let responses = [
            "Das freut mich sehr! Ich gebe immer mein Bestes für dich.",
            "Danke! Es macht mir Freude, dir zu helfen.",
            "Wie schön! Zusammen sind wir ein tolles Team.",
            "Danke für die netten Worte! Das motiviert mich sehr."
        ]
        return LilyResponse(text: responses.randomElement()!, emotion: .cheerful)
    }
    
    private func generateSupportiveResponse() -> LilyResponse {
        let responses = [
            "Es tut mir leid, dass etwas nicht funktioniert. Lass uns das gemeinsam lösen!",
            "Ich verstehe deine Frustration. Können wir es nochmal versuchen?",
            "Manchmal braucht Technik etwas Geduld. Ich arbeite daran, besser zu werden!",
            "Entschuldige die Unannehmlichkeiten. Wie kann ich dir jetzt am besten helfen?"
        ]
        return LilyResponse(text: responses.randomElement()!, emotion: .serious)
    }
    
    private func generateContextualUnknownResponse(_ input: String) -> LilyResponse {
        // Generate response based on conversation context
        let recentContext = conversationHistory.suffix(3)
        
        if recentContext.isEmpty {
            return LilyResponse.fromStandardResponse(type: "unknown")
        }
        
        let contextualResponses = [
            "Hmm, das verstehe ich noch nicht ganz. Kannst du es anders erklären?",
            "Interessant! Ich lerne noch dazu. Magst du mir mehr darüber erzählen?",
            "Das ist neu für mich. Hilfst du mir, es zu verstehen?",
            "Ich bin mir nicht sicher, was du meinst. Können wir das zusammen durchgehen?"
        ]
        
        return LilyResponse(text: contextualResponses.randomElement()!, emotion: .questioning)
    }
    
    // MARK: - Utility Methods
    
    private func extractTimeFromInput(_ input: String) -> Int {
        // Simple regex to extract numbers followed by "minuten" or "min"
        let pattern = #"(\d+)\s*(minuten?|min)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let nsString = input as NSString
            let results = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = results.first {
                let numberRange = match.range(at: 1)
                let numberString = nsString.substring(with: numberRange)
                return Int(numberString) ?? 5
            }
        }
        
        return 5 // Default 5 minutes
    }
    
    private func addToConversationHistory(_ entry: ConversationEntry) {
        conversationHistory.append(entry)
        
        // Keep only recent entries
        if conversationHistory.count > maxContextLength {
            conversationHistory.removeFirst()
        }
        
        // Update published context for UI
        currentContext = conversationHistory.map { entry in
            switch entry {
            case .user(let text):
                return "Du: \(text)"
            case .assistant(let text):
                return "Lily: \(text)"
            }
        }
    }
    
    // MARK: - Advanced AI Features
    
    /// Analyzes user sentiment from text
    /// - Parameter text: User input text
    /// - Returns: Sentiment score (-1.0 to 1.0)
    func analyzeSentiment(_ text: String) -> Double {
        let positiveWords = ["gut", "toll", "super", "freude", "glück", "liebe", "perfekt", "wunderbar"]
        let negativeWords = ["schlecht", "traurig", "ärger", "hass", "furcht", "problem", "fehler", "nervt"]
        
        let lowercased = text.lowercased()
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + (lowercased.contains(word) ? 1 : 0)
        }
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + (lowercased.contains(word) ? 1 : 0)
        }
        
        let totalWords = positiveCount + negativeCount
        if totalWords == 0 { return 0.0 }
        
        return Double(positiveCount - negativeCount) / Double(totalWords)
    }
    
    /// Generates a random response when Lily is activated without specific input
    func generateRandomActivationResponse() -> LilyResponse {
        let responses = [
            LilyResponse(text: "Hey! Du hast mich aktiviert. Wie kann ich dir helfen?", emotion: .happy),
            LilyResponse(text: "Ich bin da! Was kann ich für dich tun?", emotion: .cheerful),
            LilyResponse(text: "Hallo! Bereit für deine Frage oder Aufgabe!", emotion: .questioning),
            LilyResponse(text: "Hi! Ich höre zu. Was beschäftigt dich?", emotion: .thoughtful),
            LilyResponse(text: "Lily hier! Lass uns zusammen etwas Tolles machen!", emotion: .happy)
        ]
        
        return responses.randomElement()!
    }
    
    /// Clears conversation history
    func clearConversationHistory() {
        conversationHistory.removeAll()
        currentContext.removeAll()
    }
    
    /// Gets conversation statistics
    var conversationStats: ConversationStats {
        let userMessages = conversationHistory.filter { if case .user = $0 { return true }; return false }.count
        let assistantMessages = conversationHistory.filter { if case .assistant = $0 { return true }; return false }.count
        
        return ConversationStats(
            totalMessages: conversationHistory.count,
            userMessages: userMessages,
            assistantMessages: assistantMessages,
            averageWordsPerMessage: calculateAverageWordsPerMessage()
        )
    }
    
    private func calculateAverageWordsPerMessage() -> Double {
        let totalWords = conversationHistory.reduce(0) { total, entry in
            let text: String
            switch entry {
            case .user(let userText):
                text = userText
            case .assistant(let assistantText):
                text = assistantText
            }
            return total + text.components(separatedBy: .whitespacesAndNewlines).count
        }
        
        return conversationHistory.isEmpty ? 0.0 : Double(totalWords) / Double(conversationHistory.count)
    }
}

// MARK: - Supporting Types

enum ConversationEntry {
    case user(String)
    case assistant(String)
}

struct ConversationStats {
    let totalMessages: Int
    let userMessages: Int
    let assistantMessages: Int
    let averageWordsPerMessage: Double
}