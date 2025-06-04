# G1 Connect App für Even Realities G1

Diese README-Datei enthält Anweisungen zur Installation, Konfiguration und Verwendung der G1 Connect App für die Even Realities G1 Smart-Brille.

## Inhalt des Projekts

- **ios_app/**: Swift-Dateien für die iOS-App (SwiftUI)
- **design/**: Design-Ressourcen und Konzepte
  - **images/**: Original-Bilder für Lily-Emotionen (PNG)
  - **bmp_images/**: Konvertierte 1-Bit BMP-Bilder für die G1-Brille
- **docs/**: Technische Dokumentation
  - **g1_bluetooth_protocol.md**: Dokumentation des Bluetooth-Protokolls
  - **test_plan.md**: Testplan für die App
- **final_report.md**: Abschlussbericht mit Projektübersicht

## Voraussetzungen

- macOS mit Xcode 14.0 oder höher
- iOS 15.0 oder höher auf dem Testgerät
- Even Realities G1 Smart-Brille
- Bluetooth-Unterstützung

## Installation

1. **Xcode-Projekt erstellen**:
   - Erstelle ein neues iOS-Projekt in Xcode (App)
   - Wähle SwiftUI als Interface
   - Setze die Deployment-Target auf iOS 15.0 oder höher

2. **Dateien importieren**:
   - Kopiere alle Swift-Dateien aus dem `ios_app/`-Ordner in dein Xcode-Projekt
   - Erstelle einen Ordner "Resources" in deinem Projekt
   - Importiere die Lily-Bilder aus dem `design/images/`-Ordner in den Resources-Ordner
   - Importiere die BMP-Bilder aus dem `design/bmp_images/`-Ordner in den Resources-Ordner

3. **Info.plist konfigurieren**:
   Füge folgende Berechtigungen zu deiner Info.plist-Datei hinzu:
   ```xml
   <key>NSBluetoothAlwaysUsageDescription</key>
   <string>Diese App benötigt Bluetooth, um mit der G1 Smart-Brille zu kommunizieren.</string>
   <key>NSBluetoothPeripheralUsageDescription</key>
   <string>Diese App benötigt Bluetooth, um mit der G1 Smart-Brille zu kommunizieren.</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Diese App benötigt Spracherkennung, um das Weckwort "Hey, Lily" zu erkennen.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Diese App benötigt Zugriff auf das Mikrofon für die Spracherkennung.</string>
   ```

4. **Projekt-Einstellungen**:
   - Aktiviere Bluetooth-Hintergrundfunktionen in den Capabilities
   - Aktiviere Background Audio für die Spracherkennung

## Verwendung

### Verbindung mit der G1-Brille

1. Schalte die G1-Brille ein und aktiviere Bluetooth
2. Starte die G1 Connect App auf deinem iOS-Gerät
3. Die App sollte automatisch nach verfügbaren G1-Brillen suchen
4. Wähle deine G1-Brille aus der Liste aus
5. Nach erfolgreicher Verbindung wird der Status in der App angezeigt

### Interaktion mit Lily

- Sage "Hey, Lily", um die Assistentin zu aktivieren
- Tippe auf den Textbereich, um mit Lily zu interagieren (Platzhalter-Antworten)
- Verwende die TouchBar der G1-Brille für zusätzliche Interaktionen

### Einstellungen anpassen

- Wechsle zum "Einstellungen"-Tab, um die G1-Brille zu konfigurieren
- Passe Helligkeit, HUD-Höhe, Textgröße und andere Parameter nach Bedarf an
- Alle Änderungen werden sofort an die Brille übertragen

## Anpassung und Erweiterung

### Lily-Bilder ersetzen

1. Erstelle neue Bilder für die verschiedenen Emotionen
2. Benenne sie entsprechend: lily_happy.png, lily_cheerful.png, etc.
3. Konvertiere sie mit dem bereitgestellten Python-Skript in 1-Bit BMP:
   ```
   python3 design/convert_to_bmp.py
   ```
4. Ersetze die vorhandenen Bilder in deinem Xcode-Projekt

### API-Integration

Um die Gemini 2.5 Flash API zu integrieren:

1. Erstelle eine neue Klasse `GeminiAPIManager.swift`
2. Implementiere die API-Aufrufe gemäß der Gemini-Dokumentation
3. Verbinde die API-Antworten mit dem `LilyViewModel`

## SwiftUI-Architektur

Die App verwendet eine moderne SwiftUI-Architektur mit folgenden Komponenten:

- **G1_ConnectApp.swift**: Haupteinstiegspunkt der App
- **ContentView.swift**: Hauptansicht mit TabView für Navigation
- **LilyView.swift**: Visual-Novel-Interface für Lily mit MVVM-Architektur
- **SettingsView.swift**: Einstellungen für die G1-Brille
- **InfoView.swift**: Informationen zur App
- **BluetoothManager.swift**: ObservableObject für Bluetooth-Kommunikation
- **SettingsManager.swift**: ObservableObject für Einstellungsverwaltung
- **SpeechRecognizer.swift**: Spracherkennung für "Hey, Lily"

## Nutzung der offiziellen Demo-App

Die Implementierung orientiert sich an der von Even Realities bereitgestellten
[EvenDemoApp](https://github.com/even-realities/EvenDemoApp). Einige Protokoll-
Features wie das periodische Heartbeat-Signal (Befehl `0x25`) und das
Verlassen aller Funktionen über `0x18` wurden übernommen. Die App sendet nun
automatisch alle acht Sekunden ein Heartbeat-Paket, sobald beide Brillenarme
verbunden sind. Bei einer Trennung wird das Heartbeat beendet.
Das Kommando zum Verlassen kann zudem über die Methode
`exitToDashboard()` im `BluetoothManager` ausgelöst werden.


## Fehlerbehebung

### Bluetooth-Verbindungsprobleme

- Stelle sicher, dass Bluetooth auf deinem iOS-Gerät aktiviert ist
- Überprüfe, ob die G1-Brille eingeschaltet und im Pairing-Modus ist
- Starte die App neu, wenn keine Verbindung hergestellt werden kann

### Spracherkennung funktioniert nicht

- Überprüfe, ob die Spracherkennungs-Berechtigungen erteilt wurden
- Stelle sicher, dass das Mikrofon nicht von einer anderen App verwendet wird
- Sprich deutlich und in einer ruhigen Umgebung

## Kontakt und Support

Bei Fragen oder Problemen wende dich bitte an den Entwickler oder das Even Realities Support-Team.

---

© 2025 G1 Connect für Even Realities G1
