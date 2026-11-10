# Quickshell · Graphite / Rose

Deine aktive Waybar-Konfiguration (`~/.config/waybar/config.jsonc`) als Quickshell-Leiste,
mit den bisherigen Desktop-Widgets im selben Design. Die separaten, inaktiven
Waybar-Moduldateien (z. B. Tailscale/WOL/Updates) werden wie bisher nicht angezeigt.

## Starten

Im Terminal deiner Hyprland-Sitzung:

```bash
~/.config/quickshell/scripts/start.sh
```

Das startet Quickshell ohne doppelte Instanzen und beendet Waybar nach erfolgreichem
Laden. Quickshell beobachtet Änderungen an den QML-Dateien automatisch.
Bei einem Fehler bleibt Waybar bestehen. Der Startmechanismus folgt dem
[Quickshell-Startcode](https://github.com/quickshell-mirror/quickshell/blob/master/src/launch/launch.cpp),
der den Daemon-Aufrufer nach Erstellen des RootWrapper benachrichtigt.

## Autostart

In `~/.config/hypr/hyprland.lua` die bisherige `hl.exec_cmd("waybar ...")`-Zeile
im `hyprland.start`-Block ersetzen durch:

```lua
hl.exec_cmd("/home/alessio/.config/quickshell/scripts/start.sh")
```

Diese Datei liegt außerhalb des hier beschreibbaren Projektordners und wurde
nicht verändert. Der bestehende SwayNC-, Hypridle- und Wallpaper-Autostart bleibt nötig.

## Bedienung

| Element | Aktion |
| --- | --- |
| Arch-Symbol | Rofi-Anwendungsmenü |
| Workspace | Wechseln; aktive und belegte Workspaces werden hervorgehoben |
| Medien | Play/Pause; Rechtsklick: Stop; Scrollen: nächster/vorheriger Titel |
| Glocke | SwayNC öffnen; Rechtsklick: Nicht stören umschalten |
| Netzwerk | WLAN-IP kopieren; Rechtsklick: nmtui |
| CPU / RAM / Temperatur | btop öffnen |
| Audio | pavucontrol; Rechtsklick: stumm; Scrollen: ±5 % (max. 100 %) |
| Mond | Vorhandenes Hyprsunset-Nachtlicht umschalten |
| Uhr | Kalender mit Monatsnavigation und Heute-Markierung |
| NY | New-York-Uhr mit automatischer Sommerzeit |
| SOL | Bestehendes CoinGecko-Skript, alle 10 Minuten; Klick öffnet Kursseite |
| Tray | Linksklick: aktivieren; Rechtsklick: Menü; Mittelklick und Scrollen unterstützt |
| Schloss | Bestehendes Hyprlock-Skript |
| Power | Sperren, Abmelden, Standby, Ausschalten; die letzten drei benötigen einen zweiten Klick |

Auf breiten Monitoren erscheinen alle Module. Unter 1500 logischen Pixeln werden
Medien, Systemwerte, New York und SOL ausgeblendet, wie in deiner kompakten Waybar.
`HDMI-A-1` erhält die persistenten Workspaces 8–10; sonst 1–5. Weitere vorhandene
Workspaces werden ergänzt. Hyprlands Lua- und klassische Dispatch-Syntax werden
über die installierte Quickshell-API unterschieden.

Der Akku erscheint nur mit vorhandenem Akku. Auch Helligkeit wird automatisch
ermittelt. Ein gemeinsamer Python-Prozess liest CPU, RAM, Temperatur und Hardware
alle drei Sekunden; es gibt keine zusätzlichen Python-Abhängigkeiten.

## Transparente Leiste

Der Leistenhintergrund ist vollständig transparent und hat keinen Außenrahmen.
Aktiver Workspace, Uhr und Hover-Flächen verwenden dezente transparente Tönungen.
Helle Sekundärtexte und dunkle Textschatten halten die Module auf wechselnden
Wallpapern lesbar. Kalender, Sitzungsmenü und Tooltips behalten ihren dunklen
Hintergrund. Fensterabstand und Menüposition folgen der Höhe der Leiste.
Die Vorschau `previews/transparent.png` zeigt einen dunklen und einen hellen Hintergrund.

## Design ändern

Farben und Schrift liegen zentral in `Theme.qml`. Die rote Akzentfarbe passt zu
deinen vorhandenen Hyprland-Fensterrändern. Die Desktop-Widgets liegen auf der
Bottom-Ebene über dem Wallpaper, unter normalen Fenstern, und fangen keine
Mausklicks ab.

## Prüfung und Vorschauen

- QML-Syntax aller neuen/geänderten Komponenten mit Qt 6 geprüft.
- Leisteninhalt, Kalender, Sitzungsmenü und Desktop-Uhr mit Quickshell offscreen
  bei 2560 und 1080 Pixeln geladen und visuell geprüft.
- `python3 -m unittest discover -s tests -v`: 5 Tests für CPU/RAM, optionale
  Hardware, Offline-Netzwerk und WLAN-Namen mit Doppelpunkten.
- Die Vorschauen in `previews/` zeigen beide geöffneten Menüs sowie einen
  Beispiel-Musiktitel auf einem neutralen Hintergrund. Live-Dienste sind in der
  abgeschotteten Ausführungsumgebung nicht erreichbar; dort sind 0 % Audio,
  Offline und ein fehlender SOL-Kurs erwartbar.
- Ein vollständiger Wayland-Test einschließlich Klicks, Tray, Audio und
  Workspace-Wechsel muss in der echten Hyprland-Sitzung erfolgen. Qt-Lint kann
  den zur Laufzeit gewählten PanelWindow-Backendtyp und dessen Margins nicht
  vollständig auflösen; die übrigen UI-Komponenten liefern keine Lint-Warnungen.

## Sicherung

Die ursprünglichen QML-Dateien liegen in `backups/original-2026-10-30/`.
Zum Zurückspielen:

```bash
cp ~/.config/quickshell/backups/original-2026-10-30/*.qml ~/.config/quickshell/
```

Für eine Rückkehr zu Waybar deren ursprüngliche Autostart-Zeile wieder verwenden
und die laufende Quickshell-Instanz mit `quickshell kill --help` gezielt auswählen.
Die Waybar-Konfiguration selbst wurde nicht geändert. Die neuen Hilfsdateien
können beim Zurückspielen liegen bleiben; die ursprüngliche `shell.qml` lädt sie nicht.
