import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App logo/icon
                    Image(systemName: "eyeglasses")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(Constants.primaryColor)
                        .padding(.top, 30)
                    
                    // App title
                    Text("G1 Connect")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Constants.primaryColor)
                    
                    // Version info
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(Constants.secondaryTextColor)
                    
                    // Description
                    Text("G1 Connect ist deine Steuerungs-App für die Even Realities G1 Smart-Brille. Sie bietet dir Zugang zu Lily, deiner persönlichen Assistentin, sowie umfassende Einstellungsmöglichkeiten für deine Brille.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(Constants.textColor)
                    
                    // Usage section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Verwendung")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.primaryColor)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            UsageStep(number: "1", text: "Verbinde deine G1 Smart-Brille über Bluetooth")
                            UsageStep(number: "2", text: "Aktiviere Lily mit dem Sprachbefehl \"\(Constants.wakeWord)\"")
                            UsageStep(number: "3", text: "Stelle Fragen oder gib Befehle")
                            UsageStep(number: "4", text: "Nutze die TouchBar der Brille für zusätzliche Interaktionen")
                            UsageStep(number: "5", text: "Passe die Einstellungen nach deinen Wünschen an")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Features section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Funktionen")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.primaryColor)
                        
                        VStack(spacing: 12) {
                            FeatureRow(icon: "person.wave.2", title: "Lily Assistent", description: "Persönliche Assistentin mit verschiedenen Emotionen")
                            FeatureRow(icon: "slider.horizontal.3", title: "Einstellungen", description: "Vollständige Kontrolle über Display und HUD")
                            FeatureRow(icon: "mic", title: "Spracherkennung", description: "Wake-Word Erkennung für freihändige Bedienung")
                            FeatureRow(icon: "wifi", title: "Bluetooth", description: "Zuverlässige Verbindung zu deiner G1 Brille")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // About section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Über")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Constants.primaryColor)
                        
                        Text("Diese App wurde entwickelt, um die Even Realities G1 Smart-Brille mit einer persönlichen Assistentin zu erweitern. Die Bilder und Antworten sind derzeit Platzhalter und werden in zukünftigen Versionen durch eine Anbindung an moderne AI-APIs erweitert.")
                            .foregroundColor(Constants.textColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
            }
            .background(Constants.backgroundColor.ignoresSafeArea())
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct UsageStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number + ".")
                .fontWeight(.bold)
                .foregroundColor(Constants.primaryColor)
                .frame(width: 20, alignment: .leading)
            Text(text)
                .foregroundColor(Constants.textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Constants.primaryColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.textColor)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Constants.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
            .preferredColorScheme(.dark)
    }
}
