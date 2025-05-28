# Visual Novel Interface Design für Lily auf Even Realities G1

## Übersicht

Dieses Dokument beschreibt das Design-Konzept für die Lily-Assistentin auf der Even Realities G1 Smart-Brille. Das Interface folgt dem Visual-Novel-Stil mit einem Anime-Girl-Charakter links und Text rechts.

## Farbschema

- **Primärfarbe (Hintergrund)**: Dunkelgrau/Schwarz (#121212)
- **Akzentfarbe**: Lila (#8A2BE2)
- **Textfarbe**: Weiß (#FFFFFF)
- **Highlight-Farbe**: Helles Lila (#BB86FC)
- **Statusfarbe**: Dunkles Lila (#4A148C)

## Layout für G1 Brille

Die G1 Brille hat eine begrenzte Anzeigebreite und unterstützt 1-Bit, 576x136 Pixel BMP-Bilder. Das Layout wird wie folgt aufgeteilt:

```
+----------------------------------------------+
|  +--------+  +---------------------------+   |
|  |        |  |                           |   |
|  |  Lily  |  |  Textbereich (max 5       |   |
|  | Avatar |  |  Zeilen pro Bildschirm)   |   |
|  |        |  |                           |   |
|  +--------+  +---------------------------+   |
|                                              |
+----------------------------------------------+
```

- **Lily Avatar**: 136x136 Pixel, links positioniert
- **Textbereich**: ~440x136 Pixel, rechts positioniert
- **Schriftgröße**: 21 (basierend auf Demo-App)

## Emotionale Variationen für Lily

Für den Anime-Girl-Platzhalter werden folgende emotionale Variationen benötigt:

1. **Neutral/Standard**: Normaler Gesichtsausdruck, leichtes Lächeln
2. **Fröhlich**: Breites Lächeln, möglicherweise geschlossene Augen
3. **Nachdenklich**: Leicht geneigter Kopf, Hand am Kinn
4. **Überrascht**: Große Augen, leicht geöffneter Mund
5. **Fragend**: Hochgezogene Augenbraue, leicht geneigter Kopf
6. **Entschlossen**: Ernster Blick, leicht zusammengezogene Augenbrauen

Alle Bilder müssen als 1-Bit, 136x136 Pixel BMP-Dateien vorbereitet werden, um auf der Brille angezeigt werden zu können.

## Interaktionsdesign

### Sprachinteraktion

- **Aktivierungsphrase**: "Hey, Lily"
- **Visuelle Rückmeldung**: Wechsel zu "aufmerksamer" Emotion beim Erkennen der Aktivierungsphrase
- **Audio-Feedback**: Kurzer Ton zur Bestätigung der Aktivierung (falls von der Brille unterstützt)

### TouchBar-Interaktion

- **Linke TouchBar**:
  - Einzelnes Tippen: Vorherige Option/Seite
  - Langes Drücken: Zurück zum Hauptmenü

- **Rechte TouchBar**:
  - Einzelnes Tippen: Nächste Option/Seite
  - Langes Drücken: Aktion bestätigen

- **Doppeltippen (beide)**: Beenden der aktuellen Funktion

### Visuelle Hinweise

Am unteren Rand des Displays werden kleine Symbole angezeigt, die auf verfügbare Interaktionen hinweisen:

```
+----------------------------------------------+
|  +--------+  +---------------------------+   |
|  |        |  |                           |   |
|  |  Lily  |  |  Textbereich              |   |
|  | Avatar |  |                           |   |
|  |        |  |                           |   |
|  +--------+  +---------------------------+   |
|  [<] Zurück    Weiter [>]  [Mic] Sprechen   |
+----------------------------------------------+
```

## iOS App Interface

Die iOS App dient als Steuerungszentrale für die Brille und bietet folgende Funktionen:

### Hauptbildschirm

- **Verbindungsstatus**: Anzeige des Verbindungsstatus zur G1 Brille
- **Lily-Avatar**: Größere Version des aktuellen Lily-Avatars
- **Letzte Interaktionen**: Liste der letzten Gespräche/Interaktionen
- **Schnellzugriff**: Buttons für häufig genutzte Funktionen (Wetter, Timer, Erinnerungen)

### Einstellungen

- **Farbschema**: Anpassung des Farbschemas (Standardmäßig Darkmode mit lila Akzenten)
- **Avatar-Auswahl**: Möglichkeit, zwischen verschiedenen Lily-Avataren zu wechseln
- **Spracheinstellungen**: Konfiguration der Spracherkennung
- **Brilleneinstellungen**: Konfiguration der Brillenverbindung

## Funktionsfluss

1. **Start**: App öffnen, Verbindung zur Brille herstellen
2. **Aktivierung**: "Hey, Lily" sagen oder in der App auf Lily tippen
3. **Interaktion**: Frage stellen oder Befehl geben
4. **Antwort**: Lily antwortet mit Text und passender Emotion
5. **Navigation**: Durch längere Antworten mit TouchBar navigieren

## Standardantworten für Prototyp

Für den ersten Prototyp werden folgende Standardantworten implementiert:

1. **Begrüßung**: "Hallo! Ich bin Lily, deine persönliche Assistentin. Wie kann ich dir helfen?"
2. **Wetter**: "Das aktuelle Wetter ist sonnig mit 22°C. Ein perfekter Tag!"
3. **Zeit**: "Es ist jetzt 14:30 Uhr."
4. **Unbekannte Anfrage**: "Entschuldige, ich verstehe deine Anfrage nicht. Kannst du es anders formulieren?"
5. **Timer**: "Timer für 5 Minuten gesetzt. Ich werde dich benachrichtigen, wenn die Zeit abgelaufen ist."
6. **Erinnerung**: "Ich habe eine Erinnerung für morgen um 10 Uhr erstellt: 'Meeting mit dem Team'."

## Nächste Schritte

1. Erstellen der Platzhalterbilder für Lily in verschiedenen Emotionen
2. Implementierung der iOS-App-Grundstruktur
3. Implementierung der Bluetooth-Verbindung zur G1 Brille
4. Integration der Spracherkennung für "Hey, Lily"
5. Implementierung der TouchBar-Interaktion
