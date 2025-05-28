# Even Realities G1 Smart-Brille: Einstellungen und Steuerungsfunktionen

## Übersicht

Dieses Dokument beschreibt die erforderlichen Einstellungs- und Steuerungsfunktionen für die Even Realities G1 Smart-Brille, die in die iOS-App integriert werden müssen.

## Helligkeitsregelung

### Manuelle Helligkeit
- Slider für die manuelle Einstellung der Display-Helligkeit
- Wertebereich: 0-100%
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

### Auto-Helligkeit
- Toggle für die automatische Helligkeitsanpassung
- Nutzt den eingebauten Umgebungslichtsensor der Brille
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

## HUD-Einstellungen

### Textgröße
- Auswahlmöglichkeiten: Klein, Mittel, Groß
- Beeinflusst die Schriftgröße aller Textelemente
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

### HUD-Höhe
- Slider zur Anpassung der vertikalen Position des HUDs im Sichtfeld
- Wertebereich: TBD (nach Protokollanalyse)
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

### HUD-Transparenz
- Slider zur Einstellung der Transparenz des HUDs
- Wertebereich: 0-100%
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

## Weitere Grundeinstellungen

### Kontrast
- Slider zur Anpassung des Display-Kontrasts
- Wertebereich: TBD (nach Protokollanalyse)
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

### Farbmodus
- Auswahlmöglichkeiten: Standard, Hoher Kontrast, Nachtmodus (falls unterstützt)
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

### Energiesparoptionen
- Toggle für Energiesparmodus
- Automatisches Ausschalten nach Inaktivität (Zeitauswahl)
- Bluetooth-Befehl: TBD (nach Protokollanalyse)

## UI-Integration

Die Einstellungen sollen in einem separaten "Einstellungen"-Bereich der App integriert werden, der über einen Button in der Hauptansicht zugänglich ist. Das Design soll dem bestehenden Darkmode mit lila Akzenten folgen.

## Speicherung

Die Einstellungen sollen:
1. Lokal auf dem iOS-Gerät gespeichert werden (UserDefaults)
2. Bei Verbindung automatisch an die Brille übertragen werden
3. Bei App-Start mit den aktuellen Einstellungen der Brille synchronisiert werden

## Nächste Schritte

1. Recherche des Bluetooth-Protokolls für Einstellungen
2. Design der Einstellungs-UI
3. Implementierung der Einstellungsfunktionen
4. Integration in die bestehende App-Struktur
5. Testen der Einstellungsübertragung
