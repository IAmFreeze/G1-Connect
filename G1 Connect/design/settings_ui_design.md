# Einstellungs-UI für Even Realities G1 Smart-Brille

## Übersicht

Dieses Dokument beschreibt das Design und die Implementierung der Einstellungs-UI für die iOS-App zur Steuerung der Even Realities G1 Smart-Brille.

## Design-Prinzipien

- **Darkmode mit lila Akzenten**: Dunkler Hintergrund mit lila Hervorhebungen für ein modernes Erscheinungsbild
- **Intuitive Bedienung**: Einfache und klare Steuerelemente für alle Einstellungen
- **Konsistenz**: Einheitliches Design mit dem Visual-Novel-Interface von Lily
- **Zugänglichkeit**: Große Bedienelemente für einfache Interaktion

## UI-Komponenten

### Hauptnavigation

- Tab-Bar am unteren Bildschirmrand mit Icons für:
  - Lily (Chat-Interface)
  - Einstellungen
  - Info/Hilfe

### Einstellungs-Bildschirm

#### Header
- Titel "Einstellungen" in lila Farbe
- Verbindungsstatus der Brille mit farbiger Statusanzeige

#### Abschnitte

1. **Display-Einstellungen**
   - Helligkeit (Slider, 0-100%)
   - Auto-Helligkeit (Toggle-Switch)
   - Kontrast (Slider, 0-100%)
   - Farbmodus (Segmented Control: Standard, Hoher Kontrast, Nachtmodus)

2. **HUD-Einstellungen**
   - HUD-Höhe (Slider, 0-100%)
   - HUD-Transparenz (Slider, 0-100%)
   - Textgröße (Segmented Control: Klein, Mittel, Groß)

3. **Energieoptionen**
   - Energiesparmodus (Toggle-Switch)
   - Automatisches Ausschalten nach (Picker: Nie, 1 Min, 5 Min, 10 Min, 30 Min)

4. **Verbindungseinstellungen**
   - Brille trennen (Button)
   - Brille neu verbinden (Button)
   - Automatisch verbinden (Toggle-Switch)

## Farbschema

- **Hintergrund**: Sehr dunkles Grau (#121212)
- **Sekundärer Hintergrund**: Etwas helleres Dunkelgrau (#1E1E1E)
- **Primärfarbe (Akzent)**: Lila (#8A2BE2)
- **Text**: Weiß (#FFFFFF)
- **Sekundärer Text**: Hellgrau (#AAAAAA)
- **Erfolg**: Grün (#4CAF50)
- **Warnung**: Gelb (#FFC107)
- **Fehler**: Rot (#F44336)

## Interaktionsfluss

1. Benutzer öffnet die App und verbindet sich mit der G1-Brille
2. Benutzer wechselt zum Einstellungs-Tab
3. Benutzer passt Einstellungen nach Bedarf an
4. Änderungen werden sofort über Bluetooth an die Brille gesendet
5. Einstellungen werden lokal gespeichert und bei erneutem Verbinden wiederhergestellt

## Implementierungsdetails

### Swift-Dateien

1. **SettingsViewController.swift**
   - Hauptcontroller für den Einstellungs-Tab
   - Enthält alle UI-Elemente und deren Layout
   - Verwaltet die Benutzerinteraktionen

2. **SettingsManager.swift**
   - Singleton-Klasse zur Verwaltung aller Einstellungen
   - Speichert Einstellungen in UserDefaults
   - Kommuniziert mit BluetoothManager zur Übertragung von Einstellungen

3. **SettingsModels.swift**
   - Definiert Datenstrukturen für alle Einstellungen
   - Enthält Enums für verschiedene Einstellungstypen

### Verbindung zum Bluetooth-Protokoll

- Jede Einstellungsänderung ruft eine entsprechende Methode in SettingsManager auf
- SettingsManager formatiert die Daten gemäß dem Bluetooth-Protokoll
- BluetoothManager sendet die formatierten Befehle an die Brille

## Responsive Design

- Auto Layout für verschiedene iPhone-Größen
- Scrollbare Ansicht für kleinere Bildschirme
- Anpassbare Textgrößen für Barrierefreiheit
