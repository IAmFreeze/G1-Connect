import Foundation
import SwiftUI

enum LilyEmotion: String, CaseIterable, Identifiable {
    case happy
    case cheerful
    case thoughtful
    case serious
    case surprised
    case questioning
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .happy: return "Glücklich"
        case .cheerful: return "Fröhlich"
        case .thoughtful: return "Nachdenklich"
        case .serious: return "Ernst"
        case .surprised: return "Überrascht"
        case .questioning: return "Fragend"
        }
    }
    
    var imageName: String {
        return "lily_\(self.rawValue)"
    }
}
