# Hyprquickpaper für Alessio

Öffnen: **Super + Shift + T**. Das Menü läuft getrennt von deiner Leiste.

## Bedienung

- Links/Rechts oder A/D: Bild wählen; im Raster auch Oben/Unten.
- Mausrad: Bild wechseln. Klick: markieren. Doppelklick oder Enter: anwenden.
- Oben rechts oder Tab: Layout wechseln. Die Auswahl wird gespeichert.
- R: Bilder und Vorlagen neu einlesen. Escape oder W: schließen.

Bilder in `~/Pictures/Wallpapers/` ablegen. Unterordner sind erlaubt.
PNG, JPEG, WebP, BMP und GIF werden erkannt. Mit Hyprpaper wird ein GIF als
Standbild gesetzt; im Menü läuft die ausgewählte GIF-Vorschau. Videos sind mit
diesem Hyprpaper-Backend nicht verfügbar. Dafür wären awww/mpvpaper nötig.
Der gewählte Hintergrund wird auf allen aktiven Monitoren gesetzt und beim
Anmelden wiederhergestellt. Der ursprüngliche rote Hintergrund bleibt als Fallback.
Jede Auswahl wechselt Hintergrund und vollständige Desktop-Farben gemeinsam.
Für neu hinzugefügte Bilder werden automatisch passende Farben erzeugt.
GTK-Anwendungen behalten ihr vorhandenes GTK-Theme.

## Layouts und komplette Quickshell-Design-Pakete

- `templates/carousel.json`: schmales, hohes Bildkarussell mit großer Mitte und
  zu den Seiten kleiner werdenden Vorschauen, angelehnt an deine Referenz.
- `templates/gallery.json`: breites Raster mit Bildnamen und grünem Akzent.

## Eine eigene Vorlage erstellen

1. Kopiere `templates/carousel.json` beispielsweise nach `templates/mein-layout.json`.
2. Ändere `name` in den gewünschten Anzeigenamen.
3. Passe die Felder an:

| Feld | Bedeutung |
| --- | --- |
| `layout` | `carousel` oder `gallery` |
| `background` | Vollbild-Hintergrund; `#AARRGGBB` erlaubt Transparenz |
| `surface` | Menüfläche; für das offene Karussell transparent lassen |
| `text`, `muted`, `accent` | Text-, Neben- und Auswahlfarbe |
| `card_width`, `card_height` | Bildgröße in logischen Pixeln |
| `radius` | Rundung |
| `spacing` | Abstand |
| `animation_ms` | Dauer der Auswahlanimation |

4. Speichern und im Menü R drücken (oder neu öffnen).
   Jede JSON-Datei mit einem unterstützten `layout` erscheint automatisch oben.

Damit erstellst du Varianten der beiden Layouts. Für eine völlig neue Anordnung
wird zusätzlich `shell.qml` erweitert.

### Ein komplettes Quickshell-Design hinzufügen

Lege für jedes Design einen eigenen Ordner in `~/.config/templates/` an. Der
Ordner braucht ein Bild und einen Unterordner `quickshell/`, dessen Inhalt
relativ nach `~/.config/quickshell/` kopiert wird. Beispiel:

```text
~/.config/templates/
└── mein-design/
    ├── template.json       # optional
    ├── preview.png         # Bild; wird auch als Wallpaper gesetzt
    └── quickshell/
        ├── shell.qml
        ├── bar.qml
        └── ...
```

Optional beschreibt `template.json` Name und Bilddateien:

```json
{
  "name": "Mein Design",
  "image": "preview.png",
  "wallpaper": "preview.png"
}
```

`image` ist die Vorschau oben im Auswahlfenster. `wallpaper` wird beim Anwenden
als Desktop-Hintergrund gesetzt; ohne Angabe wird `image` verwendet. Das Paket
erscheint nach R oder beim nächsten Öffnen oben im Picker. Ein Klick kopiert die
Dateien, setzt das Wallpaper und startet die Haupt-Quickshell-Konfiguration neu.
Vorhandene Dateien, die ersetzt werden, liegen als Sicherung unter
`~/.local/state/hyprquickpaper/template-backups/`. Dateien aus dem Paket werden
über vorhandene Dateien gelegt; Dateien, die nicht im Paket stehen, bleiben
erhalten. `hyprquickpaper/` darf ein Paket nicht überschreiben.

`config.json` bestimmt den Bildordner, rekursive Suche und das Standardlayout.
Die zuletzt gewählte Vorlage hat Vorrang vor dem Standard. Zustand:
`~/.local/state/hyprquickpaper/`; Vorschaubilder: `~/.cache/hyprquickpaper/thumbs/`.
Die Vorschaunamen berücksichtigen Dateipfad, Größe und Änderungszeit, sodass
auch gleichnamige Dateien aus Unterordnern und geänderte Bilder korrekt laden.

## Einstellungen und Themes

- **Super + I**: komplettes Einstellungsfenster.
- **Super + S**: Schnelleinstellungen.
- Zahnrad in der Leiste: links Schnelleinstellungen, rechts alle Einstellungen.
- Themes unter `~/.config/quickshell/SettingsHub/themes/` enthalten Hintergrund und
  Desktop-Farben. Neue Themes benötigen `desktop: true` und einen gültigen
  `wallpaper`-Pfad. Reine Farbpaletten werden nicht mehr angeboten.
- `SettingsHub/SettingsPages/ConfigPage.qml` verlinkt deine Konfigurationsdateien.
- Monitor- und Eingabeänderungen werden in `~/.config/quickshell/state/` gespeichert
  und am Ende deiner Hyprland-Lua-Datei geladen. Zurücksetzen erfolgt auf der Seite.

Der bisherige Floating-Shortcut liegt jetzt auf **Super + Ctrl + T**.
Workspace-Wechsel verwenden eine horizontale Slide-Animation.

## Herkunft

Angepasst nach https://github.com/43PR/dotfiles, Stand d969cba.
Die ursprünglichen Dateien wurden nur als Referenz unter `/tmp/43pr-quickshell-review`
heruntergeladen. Die übrige Desktop-Shell und Benachrichtigungen bleiben deine bisherigen.

## Bluetooth einmalig aktivieren

Dein Bluetooth-Dienst war bei der Einrichtung inaktiv. Die Seite Bluetooth hat
für diesen Fall den Knopf „Bluetooth-Dienst aktivieren …“. Er öffnet ein Terminal
für `sudo systemctl enable --now bluetooth.service`; dort gibst du dein Systempasswort
ein. Danach ist der Dienst auch nach einem Neustart aktiv. Ein Hardware-Adapter
muss natürlich vorhanden sein.

Die System-, Audio-, Netzwerk-, Bluetooth-, Display-, Eingabe- und Speicherseiten
sowie das verschiebbare Einstellungsfenster stammen aus der 43PR-Vorlage und wurden
an deine Umgebung angebunden. Die bestehenden Tray-, Kalender-, New-York-, SOL-,
Desktop-, Medien-, Nachtlicht-, Sperr- und Benachrichtigungsfunktionen bleiben erhalten.

## Komplette Desktop-Themes wechseln

**Super + Shift + T** öffnet direkt die kompletten Themes.
Alternativ **Super + I → Themes → Komplette Themes als Karussell öffnen**.

- **Original · Rot**: dein bisheriges Design; stellt die vor dem ersten kompletten
  Theme-Wechsel gesicherten Farbdateien wieder her und setzt das rote Bild
  aus seiner Theme-JSON-Datei.
- **Mist Forest**: Nebelwald-Wallpaper, dunkles Tannengrün, Salbei und Blaugrau.

Enter oder „Theme anwenden“ wechselt Wallpaper, Quickshell-Leiste, Desktop-Widgets,
Einstellungen, Rofi-Farben, Hyprlock-Farben, SwayNC-Farben, Hyprland-Fensterränder
und Ghostty-Farbpalette. GTK-Anwendungen behalten ihr bisheriges GTK-Theme.
Die bestehenden Tastenkürzel, Layouts, Funktionen und Profilbilder bleiben erhalten.
Die Sicherung liegt in `~/.config/quickshell/state/original-desktop.json`.
Bei einem Fehler versucht der Theme-Wechsel, den vorherigen Zustand wiederherzustellen.

### Ein weiteres komplettes Theme erstellen

1. Kopiere `~/.config/quickshell/SettingsHub/themes/mist-forest.json` nach
   `~/.config/quickshell/SettingsHub/themes/mein-theme.json`.
2. Ändere `name` und `wallpaper` (z. B. `~/Pictures/Wallpapers/mein-bild.png`).
3. Passe die Hex-Farben unter `colors` an. `desktop: true` aktiviert den kompletten Wechsel.
4. Lege das Bild im angegebenen Pfad ab. Menü neu öffnen oder R drücken.

Reine Farbpaletten wie Ocean oder Amber bleiben als Dateien erhalten, werden
aber nicht mehr angeboten oder einzeln angewendet. Es gibt keinen getrennten
Wallpaper-Modus mehr. Neue Bilder im Wallpaper-Ordner erhalten beim Öffnen oder
mit R automatisch eine vollständige Theme-Datei (`auto-…json`). Bereits von Hand
gestaltete Themes wie Mist Forest behalten ihre abgestimmten Farben.

### Hintergrund-Quelle und Prompt

`~/Pictures/Wallpapers/mist-forest.png` wurde mit dem eingebauten Imagegen-Werkzeug
neu erzeugt (keine CLI/API-Schlüssel). Verwendeter Prompt:

> Create a polished ultrawide desktop wallpaper for a complete Linux desktop theme named Mist Forest. Landscape 21:9 aspect ratio, highest available resolution. A quiet dark evergreen forest in layered blue-green mist, subtle distant mountain silhouettes, delicate pale sage light through the trees, cinematic photographic realism, rich dark pine green and charcoal shadows with restrained desaturated mint highlights. Elegant calm atmosphere, plenty of visually quiet space for desktop widgets, readable behind a transparent glass settings panel. No people, no buildings, no lettering, no logos, no interface elements, no borders. One continuous landscape, not a collage.

## Übergang beim Wechseln

Wallpaper- und komplette Theme-Wechsel erhalten einen horizontalen Wischübergang
mit weichem Anlaufen/Abbremsen und leichter Bewegung des alten Bildes (ca. 0,8 s).
Die Einblendung liegt unter deinen Fenstern auf allen Monitoren, nimmt keine
Maus- oder Tastatureingaben an und beendet sich selbst. Der Auswahlbildschirm
blendet sich während des Wechsels aus; Fehler werden dort anschließend angezeigt.
Mit `"transitions": false` in `config.json` lässt sich der Effekt abschalten.
