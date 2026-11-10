import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
Flickable {
    contentHeight: content.implicitHeight + 40
    clip: true
    ColumnLayout {
        id: content
        width: parent.width - 20
        spacing: 14
        Text { text: "Deine Konfiguration"; color: Theme.text; font.pixelSize: 25 }
        Text { Layout.fillWidth: true; text: "Dateien im zugeordneten Editor öffnen. Die bestehenden Funktionen und Tastenkürzel bleiben erhalten."; color: Theme.textDim; wrapMode: Text.WordWrap }
        Repeater {
            model: [
                {name: "Hyprland · Fenster, Workspaces und Tastenkürzel", path: ".config/hypr/hyprland.lua"},
                {name: "Wallpaper-Menü · Ordner und Standardlayout", path: ".config/quickshell/hyprquickpaper/config.json"},
                {name: "Wallpaper-Layouts", path: ".config/quickshell/hyprquickpaper/templates"},
                {name: "Quickshell-Farbthemes", path: ".config/quickshell/SettingsHub/themes"},
                {name: "Rofi · Anwendungsmenü", path: ".config/rofi/config.rasi"},
                {name: "Hyprlock · Sperrbildschirm", path: ".config/hypr/hyprlock.conf"},
                {name: "SwayNC · Benachrichtigungen", path: ".config/hypr/swaync-config.json"},
                {name: "Anleitung · Wallpaper-Menü und eigene Vorlagen", path: ".config/quickshell/hyprquickpaper/README.md"}
            ]
            HubButton {
                required property var modelData
                text: modelData.name
                onClicked: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/" + modelData.path])
            }
        }
        HubButton { text: "Netzwerk im Terminal (nmtui)"; onClicked: Quickshell.execDetached(["ghostty", "-e", "nmtui"]) }
        Text { Layout.fillWidth: true; text: "Super + Shift + T   Wallpapers\nSuper + I   Einstellungen\nSuper + S   Schnelleinstellungen\nSuper + Ctrl + T   Fenster schwebend umschalten"; color: Theme.accent; font.pixelSize: 13; lineHeight: 1.5 }
    }
}
