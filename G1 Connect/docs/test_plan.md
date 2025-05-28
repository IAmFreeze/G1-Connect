# Testplan für G1 Connect App

## Übersicht
Dieses Dokument beschreibt den Testplan für die G1 Connect App, die zur Steuerung der Even Realities G1 Smart-Brille entwickelt wurde. Der Testplan umfasst alle wichtigen Funktionen und Interaktionen der SwiftUI-basierten App.

## 1. Verbindungstests

### 1.1 Bluetooth-Verbindung
- [ ] App startet und initialisiert Bluetooth-Manager korrekt
- [ ] Bluetooth-Scan findet verfügbare G1-Brillen
- [ ] Verbindung mit linker und rechter Seite der Brille wird hergestellt
- [ ] Verbindungsstatus wird korrekt in der UI angezeigt
- [ ] Automatische Wiederverbindung funktioniert
- [ ] Trennen der Verbindung funktioniert

## 2. Lily-Assistent Tests

### 2.1 Visuelle Darstellung
- [ ] Lily-Avatar wird korrekt angezeigt
- [ ] Verschiedene Emotionen werden korrekt dargestellt:
  - [ ] Happy
  - [ ] Cheerful
  - [ ] Thoughtful
  - [ ] Serious
  - [ ] Surprised
  - [ ] Questioning

### 2.2 Spracherkennung
- [ ] "Hey, Lily" Weckwort wird korrekt erkannt
- [ ] Lily reagiert auf das Weckwort mit entsprechender Animation
- [ ] Spracherkennung funktioniert in verschiedenen Umgebungen

### 2.3 Interaktion
- [ ] Tippen auf den Textbereich löst Antworten aus
- [ ] Standard-Antworten werden korrekt angezeigt
- [ ] Emotionen wechseln entsprechend der Antworten

## 3. Einstellungs-UI Tests

### 3.1 Display-Einstellungen
- [ ] Helligkeitsregler funktioniert und sendet korrekte Befehle
- [ ] Auto-Helligkeit-Toggle funktioniert und sendet korrekte Befehle
- [ ] Kontrastregler funktioniert und sendet korrekte Befehle
- [ ] Farbmodus-Auswahl funktioniert und sendet korrekte Befehle

### 3.2 HUD-Einstellungen
- [ ] HUD-Höhenregler funktioniert und sendet korrekte Befehle
- [ ] HUD-Transparenzregler funktioniert und sendet korrekte Befehle
- [ ] Textgrößen-Auswahl funktioniert und sendet korrekte Befehle

### 3.3 Energieoptionen
- [ ] Energiesparmodus-Toggle funktioniert und sendet korrekte Befehle
- [ ] Automatisches Ausschalten-Auswahl funktioniert und sendet korrekte Befehle

### 3.4 Verbindungseinstellungen
- [ ] "Brille trennen" Button funktioniert
- [ ] "Brille neu verbinden" Button funktioniert
- [ ] Automatisch verbinden-Toggle wird korrekt gespeichert

## 4. Bluetooth-Protokoll Tests

### 4.1 Befehlsübertragung
- [ ] Helligkeitsbefehl [0xF5, 0x01, Wert] wird korrekt gesendet
- [ ] Auto-Helligkeitsbefehl [0xF5, 0x02, Status] wird korrekt gesendet
- [ ] HUD-Höhenbefehl [0xF5, 0x03, Wert] wird korrekt gesendet
- [ ] Textgrößenbefehl [0xF5, 0x04, Wert] wird korrekt gesendet
- [ ] HUD-Transparenzbefehl [0xF5, 0x05, Wert] wird korrekt gesendet
- [ ] Kontrastbefehl [0xF5, 0x06, Wert] wird korrekt gesendet
- [ ] Farbmodusbefehl [0xF5, 0x07, Wert] wird korrekt gesendet
- [ ] Energiesparmodusbefehl [0xF5, 0x08, Status] wird korrekt gesendet
- [ ] Automatisches Ausschalten-Befehl [0xF5, 0x09, Wert] wird korrekt gesendet

### 4.2 Bildübertragung
- [ ] 1-Bit BMP-Bilder werden korrekt an die Brille übertragen
- [ ] Verschiedene Emotionsbilder werden korrekt angezeigt

## 5. SwiftUI-spezifische Tests

### 5.1 Navigation
- [ ] TabView Navigation funktioniert korrekt
- [ ] Wechsel zwischen Lily, Einstellungen und Info funktioniert

### 5.2 Responsiveness
- [ ] UI passt sich verschiedenen iPhone-Größen an
- [ ] Landscape- und Portrait-Modus werden unterstützt
- [ ] Scrolling in allen Ansichten funktioniert korrekt

### 5.3 State Management
- [ ] @Published Properties werden korrekt aktualisiert
- [ ] UI reagiert auf Zustandsänderungen
- [ ] Einstellungen werden korrekt in UserDefaults gespeichert
- [ ] Einstellungen werden beim App-Neustart korrekt geladen

## 6. Fehlerfälle

### 6.1 Verbindungsfehler
- [ ] App zeigt angemessene Fehlermeldungen bei Verbindungsproblemen
- [ ] Wiederverbindungsversuche werden korrekt durchgeführt
- [ ] App bleibt stabil bei Verbindungsabbrüchen

### 6.2 Berechtigungsfehler
- [ ] App fordert Bluetooth-Berechtigungen korrekt an
- [ ] App fordert Spracherkennungs-Berechtigungen korrekt an
- [ ] App bleibt funktionsfähig, wenn Berechtigungen verweigert werden

## 7. Performance-Tests

### 7.1 Ressourcenverbrauch
- [ ] App verbraucht angemessene CPU-Ressourcen
- [ ] App verbraucht angemessenen Speicher
- [ ] Batterieverbrauch ist optimiert

### 7.2 Reaktionszeit
- [ ] UI-Interaktionen sind flüssig und reaktionsschnell
- [ ] Bluetooth-Befehle werden ohne spürbare Verzögerung gesendet
- [ ] Spracherkennung reagiert prompt auf das Weckwort
