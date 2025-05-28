# Even Realities G1 Smart Brille - iOS API Zusammenfassung

## Übersicht

Diese Dokumentation fasst die wichtigsten iOS-Schnittstellen für die Kommunikation mit der Even Realities G1 Smart Brille zusammen. Die Informationen basieren auf der Analyse des offiziellen [EvenDemoApp](https://github.com/even-realities/EvenDemoApp) Repositories.

## Bluetooth-Verbindung

### Dual-Bluetooth-Architektur

Die G1 Brille verwendet eine einzigartige Dual-Bluetooth-Architektur:
- Jeder Brillenarm entspricht einer separaten BLE-Verbindung (links und rechts)
- Beide Verbindungen müssen für die vollständige Funktionalität hergestellt werden
- Die Geräte werden als Paar erkannt und verwaltet

### Verbindungsaufbau

```swift
// Geräte scannen
centralManager.scanForPeripherals(withServices: nil, options: nil)

// Verbindung herstellen (beide Seiten)
centralManager.connect(leftPeripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
centralManager.connect(rightPeripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
```

### Dienste und Charakteristiken

Die Brille verwendet UART-Dienste für die Kommunikation:

```swift
// UART Service und Charakteristiken UUIDs
UARTServiceUUID = CBUUID(string: ServiceIdentifiers.uartServiceUUIDString)
UARTTXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartTXCharacteristicUUIDString)
UARTRXCharacteristicUUID = CBUUID(string: ServiceIdentifiers.uartRXCharacteristicUUIDString)
```

## Kommunikationsprotokolle

### GATT-Protokoll Befehle

Die wichtigsten Befehle für die Kommunikation mit der Brille:

```swift
enum AG_BLE_REQ : UInt8 {
    case BLE_REQ_TRANSFER_MIC_DATA = 241 // 0xF1 - Mikrofondaten übertragen
    case BLE_REQ_DEVICE_ORDER = 245      // 0xF5 - Gerätebefehl
}
```

### Mikrofon-Aktivierung

```swift
// Mikrofon aktivieren (an die rechte Seite senden)
writeData(writeData: Data([0x0E, 0x01]), lr: "R")
```

### TouchBar-Interaktion

Die Brille verfügt über TouchBars auf beiden Seiten:
- Langes Drücken der linken TouchBar aktiviert den Even AI-Modus
- Einzelnes Tippen wechselt zwischen automatischem und manuellem Modus
- Im manuellen Modus: linke TouchBar für Seite hoch, rechte TouchBar für Seite runter
- Doppeltippen beendet die Even AI-Funktion

### Befehlsstruktur für TouchBar-Ereignisse

```
0xF5 0x00 - Funktionen schließen oder Anzeigedetails ausschalten
0xF5 0x01 - Bei Prüfung des Dashboards, Wechsel zur nächsten QuickNote oder Benachrichtigungsdetails
0xF5 0x04/0x05 - Stummmodus umschalten
0xF5 0x17 (23) - Even AI starten
0xF5 0x18 (24) - Even AI-Aufnahme beenden
```

## Datenübertragung

### Textübertragung

Der Prozess zur Textübertragung an die Brille:

1. Text in Zeilen aufteilen basierend auf der Anzeigebreite (488 Pixel) und Schriftgröße (21)
2. Zeilen pro Bildschirm kombinieren (5 Zeilen pro Bildschirm in der Demo)
3. Text-Pakete mit dem Protokoll an die Brille senden

```swift
// Textübertragungsbefehl: 0x4E (78)
// Struktur: [0x4E, seq, total_package_num, current_package_num, newscreen, ...]
```

### Bildübertragung

Die Brille unterstützt 1-Bit, 576x136 Pixel BMP-Bilder:

1. BMP-Daten in Pakete aufteilen (194 Bytes pro Paket)
2. 0x15-Befehl und syncID hinzufügen
3. Pakete an beide BLE-Verbindungen senden
4. Nach dem letzten Paket den Paketendbefehl [0x20, 0x0D, 0x0E] senden
5. CRC-Prüfbefehl über 0x16-Befehl senden

```swift
// Erstes Paket: [0x15, index & 0xff, 0x00, 0x1c, 0x00, 0x00] + Daten
// Weitere Pakete: [0x15, index & 0xff] + Daten
// Paketende: [0x20, 0x0D, 0x0E]
```

## Spracherkennung

Die App verwendet die iOS Speech-Framework für die Spracherkennung:

```swift
// Spracherkennung starten
recognizer = SFSpeechRecognizer(locale: Locale(identifier: localIdentifier ?? "en-US"))
recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
recognitionRequest.shouldReportPartialResults = true
recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { ... }

// PCM-Daten hinzufügen
func appendPCMData(_ pcmData: Data) {
    // PCM-Daten zum Erkennungsrequest hinzufügen
    recognitionRequest.append(audioBuffer)
}

// Spracherkennung stoppen
func stopRecognition() {
    recognitionTask?.cancel()
    // Erkannten Text an Bluetooth-Manager senden
    BluetoothManager.shared.blueSpeechSink?(["script": self.lastRecognizedText])
}
```

## Anzeige-Eigenschaften

- Maximale Anzeigebreite: 488 Pixel
- Empfohlene Zeilenhöhe: 5 Zeilen pro Bildschirm
- Unterstützte Bildformate: 1-Bit, 576x136 Pixel BMP

## Implementierungshinweise für Visual Novel Interface

Für die Implementierung eines Visual-Novel-Interfaces mit Lily:

1. **Dual-Bluetooth-Verbindung**: Beide Brillenarme müssen verbunden sein
2. **Bildanzeige**: Anime-Girl-Bilder als 1-Bit, 576x136 BMP vorbereiten
3. **Textanzeige**: Text in 5-Zeilen-Blöcke aufteilen, Schriftgröße 21
4. **TouchBar-Integration**: 
   - Links: Zurück/Vorherige Option
   - Rechts: Weiter/Nächste Option
5. **Spracherkennung**: "Hey, Lily" als Aktivierungsphrase implementieren
6. **Emotionen**: Verschiedene BMP-Bilder für unterschiedliche Emotionen vorbereiten

## Nächste Schritte

1. Interface-Design erstellen
2. Platzhalterbilder für Lily in verschiedenen Emotionszuständen vorbereiten
3. Grundlegende iOS-App-Struktur implementieren
4. Bluetooth-Verbindung zur Brille implementieren
5. Text- und Bildübertragung testen
