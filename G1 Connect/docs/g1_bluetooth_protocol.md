# G1 Smart-Brille: Bluetooth-Protokoll für Einstellungen

## Übersicht

Dieses Dokument fasst die Ergebnisse der Recherche zum Bluetooth-Protokoll für die Steuerung der Even Realities G1 Smart-Brille zusammen, insbesondere im Hinblick auf Einstellungen und Konfigurationsoptionen.

## Bluetooth-Verbindungsarchitektur

Die G1-Brille verwendet eine duale Bluetooth-Verbindung:
- Linke Seite der Brille (mit "_L_" im Namen)
- Rechte Seite der Brille (mit "_R_" im Namen)

Beide Seiten müssen verbunden sein, um die volle Funktionalität zu gewährleisten.

## UART-Service und Charakteristiken

Die Kommunikation erfolgt über einen UART-Service mit folgenden UUIDs:
- Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- TX Charakteristik (Schreiben): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- RX Charakteristik (Lesen): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

## Befehlsstruktur

Basierend auf der Analyse des BluetoothManager.swift und GattProtocal.swift werden Befehle als Byte-Arrays über die writeData-Methode gesendet. Die grundlegende Struktur für Befehle ist:

```
[Befehlstyp, Parameter1, Parameter2, ...]
```

### Identifizierte Befehle

1. **Initialisierung**: `[0x4D, 0x01]`
   - Wird nach der Verbindung gesendet, um die Kommunikation zu initialisieren

2. **Datenübertragung**: `[0x9A, 0x01]` (vermutlich für Bild- und Textdaten)
   - Wird in der writeData-Methode verwendet

### Protokoll für Einstellungen

Basierend auf der Analyse des Codes und ähnlichen Bluetooth-Protokollen für AR/VR-Geräte, können wir folgende Befehlsstruktur für Einstellungen ableiten:

1. **Helligkeit einstellen**:
   - Befehl: `[0xF5, 0x01, Helligkeitswert]`
   - Helligkeitswert: 0-100 (0x00-0x64)

2. **Auto-Helligkeit umschalten**:
   - Befehl: `[0xF5, 0x02, Status]`
   - Status: 0 = Aus, 1 = Ein

3. **HUD-Höhe einstellen**:
   - Befehl: `[0xF5, 0x03, Höhenwert]`
   - Höhenwert: 0-100 (0x00-0x64)

4. **Textgröße einstellen**:
   - Befehl: `[0xF5, 0x04, Größenwert]`
   - Größenwert: 1 = Klein, 2 = Mittel, 3 = Groß

5. **HUD-Transparenz einstellen**:
   - Befehl: `[0xF5, 0x05, Transparenzwert]`
   - Transparenzwert: 0-100 (0x00-0x64)

6. **Kontrast einstellen**:
   - Befehl: `[0xF5, 0x06, Kontrastwert]`
   - Kontrastwert: 0-100 (0x00-0x64)

7. **Farbmodus einstellen**:
   - Befehl: `[0xF5, 0x07, Moduswert]`
   - Moduswert: 1 = Standard, 2 = Hoher Kontrast, 3 = Nachtmodus

8. **Energiesparmodus umschalten**:
   - Befehl: `[0xF5, 0x08, Status]`
   - Status: 0 = Aus, 1 = Ein

## Implementierungshinweise

1. Alle Befehle müssen an beide Seiten der Brille (links und rechts) gesendet werden.
2. Die Kommunikation erfolgt über die `writeData`-Methode im BluetoothManager.
3. Vor dem Senden von Einstellungsbefehlen muss eine erfolgreiche Verbindung hergestellt sein.
4. Nach dem Senden von Einstellungsbefehlen sollte eine Bestätigung abgewartet werden.

## Offene Fragen und Annahmen

Da die genaue Befehlsstruktur für Einstellungen nicht explizit im Code dokumentiert ist, basieren die oben genannten Befehle auf:
1. Analyse des vorhandenen Codes
2. Typischen Bluetooth-Protokollen für ähnliche Geräte
3. Logischen Annahmen basierend auf der Funktionalität

Diese Befehle müssen während der Implementierung getestet und möglicherweise angepasst werden.

## Nächste Schritte

1. Implementierung einer Einstellungs-UI basierend auf diesen Protokolldetails
2. Testen der Befehle mit einer tatsächlichen G1-Brille
3. Anpassung der Befehle basierend auf den Testergebnissen
