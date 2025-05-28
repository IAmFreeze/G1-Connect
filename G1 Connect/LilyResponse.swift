import Foundation

struct LilyResponse {
    let text: String
    let emotion: LilyEmotion
    
    init(text: String, emotion: LilyEmotion) {
        self.text = text
        self.emotion = emotion
    }
    
    // Creates response from standard response type
    static func fromStandardResponse(type: String) -> LilyResponse {
        let text = Constants.standardResponses[type] ?? Constants.standardResponses["unknown"]!
        let emotion = getEmotionForResponseType(type)
        return LilyResponse(text: text, emotion: emotion)
    }
    
    // Maps response types to appropriate emotions
    private static func getEmotionForResponseType(_ type: String) -> LilyEmotion {
        switch type {
        case "greeting":
            return .happy
        case "weather":
            return .cheerful
        case "time", "reminder":
            return .thoughtful
        case "timer":
            return .serious
        case "unknown":
            return .questioning
        default:
            return .happy
        }
    }
    
    // Process user input and return appropriate response
    static func processInput(_ input: String) -> LilyResponse {
        let lowercasedInput = input.lowercased()
        
        if lowercasedInput.contains("hallo") || lowercasedInput.contains("hi") {
            return fromStandardResponse(type: "greeting")
        } else if lowercasedInput.contains("wetter") {
            return fromStandardResponse(type: "weather")
        } else if lowercasedInput.contains("zeit") || lowercasedInput.contains("uhr") {
            return fromStandardResponse(type: "time")
        } else if lowercasedInput.contains("timer") || lowercasedInput.contains("wecker") {
            return fromStandardResponse(type: "timer")
        } else if lowercasedInput.contains("erinner") || lowercasedInput.contains("notiz") {
            return fromStandardResponse(type: "reminder")
        } else {
            return fromStandardResponse(type: "unknown")
        }
    }
}
