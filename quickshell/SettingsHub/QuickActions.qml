import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".." as Desktop

Scope {
    id: root
    property bool showing: false
    property bool wifiOn: false
    property bool dndOn: false
    property int brightness: 0
    property bool hasBrightness: false
    function launch(args) { Quickshell.execDetached(args) }
    function openSettings(page) {
        showing = false
        launch(["qs", "ipc", "call", "settings", page])
    }
    IpcHandler {
        target: "qa"
        function toggle(): void { root.showing = !root.showing }
        function hide(): void { root.showing = false }
    }
    onShowingChanged: {
        if (showing) { wifi.running = true; dnd.running = true; light.running = true }
    }
    Timer { interval: 3000; running: root.showing; repeat: true; onTriggered: { wifi.running = true; dnd.running = true } }
    Process {
        id: wifi
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: dnd
        command: ["timeout", "2", "swaync-client", "-D"]
        stdout: StdioCollector { onStreamFinished: root.dndOn = text.trim() === "true" }
    }
    Process {
        id: light
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                root.hasBrightness = parts.length >= 4
                root.brightness = parseInt(parts[3]) || 0
            }
        }
    }
    Process {
        id: wifiToggle
        onExited: wifi.running = true
    }
    Process {
        id: dndToggle
        command: ["timeout", "2", "swaync-client", "-d"]
        onExited: dnd.running = true
    }
    LazyLoader {
        active: root.showing
        PanelWindow {
            anchors { top: true; right: true }
            margins { top: 55; right: 20 }
            implicitWidth: 430
            implicitHeight: contents.implicitHeight + 40
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quick-settings"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.bg
                border.color: Theme.border
                focus: true
                Keys.onEscapePressed: root.showing = false
                ColumnLayout {
                    id: contents
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                    spacing: 14
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Schnelleinstellungen"; color: Theme.text; font.pixelSize: 19; font.family: Theme.fontFamily }
                        Item { Layout.fillWidth: true }
                        HubButton { text: "×"; onClicked: root.showing = false }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        HubButton {
                            Layout.fillWidth: true
                            text: root.wifiOn ? "WLAN · An" : "WLAN · Aus"; selected: root.wifiOn
                            onClicked: { wifiToggle.command = ["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"]; wifiToggle.running = true }
                        }
                        HubButton {
                            Layout.fillWidth: true
                            text: BluetoothState.powered ? "Bluetooth · An" : "Bluetooth · Aus"; selected: BluetoothState.powered
                            onClicked: { if (BluetoothState.adapter) BluetoothState.adapter.enabled = !BluetoothState.adapter.enabled }
                        }
                        HubButton {
                            Layout.fillWidth: true
                            text: root.dndOn ? "Nicht stören · An" : "Nicht stören · Aus"; selected: root.dndOn
                            onClicked: dndToggle.running = true
                        }
                        HubButton {
                            Layout.fillWidth: true
                            text: "Nachtlicht"; selected: Desktop.SystemStatus.nightlight.class === "on"
                            onClicked: root.launch(["sh", Quickshell.env("HOME") + "/.config/hypr/scripts/nightlight.sh", "toggle"])
                        }
                    }
                    Text { text: "Lautstärke"; color: Theme.textDim; font.pixelSize: 12 }
                    RowLayout {
                        Layout.fillWidth: true
                        HubButton { text: "−"; onClicked: root.launch(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]) }
                        Desktop.VolumeMonitor { id: volume }
                        Text { text: volume.muted ? "Stumm" : volume.volume + "%"; color: Theme.text; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                        HubButton { text: "+"; onClicked: root.launch(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+"]) }
                        HubButton { text: "Stumm"; selected: volume.muted; onClicked: root.launch(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) }
                    }
                    Text { visible: root.hasBrightness; text: "Helligkeit · " + root.brightness + "%"; color: Theme.textDim; font.pixelSize: 12 }
                    RowLayout {
                        visible: root.hasBrightness
                        Layout.fillWidth: true
                        HubButton { text: "−"; onClicked: { root.launch(["brightnessctl", "set", "5%-"]); light.running = true } }
                        Item { Layout.fillWidth: true }
                        HubButton { text: "+"; onClicked: { root.launch(["brightnessctl", "set", "+5%"]); light.running = true } }
                    }
                    RowLayout {
                        HubButton { text: "WLAN …"; onClicked: root.openSettings("network") }
                        HubButton { text: "Bluetooth …"; onClicked: root.openSettings("bluetooth") }
                        HubButton { text: "Audio …"; onClicked: root.openSettings("sound") }
                    }
                    RowLayout {
                        HubButton { text: "Themes"; onClicked: root.openSettings("themes") }
                        HubButton { text: "Alle Einstellungen"; onClicked: root.openSettings("open") }
                    }
                }
            }
        }
    }
}
