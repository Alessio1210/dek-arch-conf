pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
    id: root
    property var shellScreen: null
    property var panelWindow: null
    property bool preview: false
    readonly property bool compact: width < 1500
    readonly property var monitor: shellScreen ? Hyprland.monitorFor(shellScreen) : null
    readonly property int activeId: monitor?.activeWorkspace?.id ?? Hyprland.focusedWorkspace?.id ?? 1
    readonly property var workspaceIds: {
        const ids = shellScreen?.name === "HDMI-A-1" ? [8, 9, 10] : [1, 2, 3, 4, 5]
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && (!compact || !monitor || ws.monitor?.name === monitor.name) && !ids.includes(ws.id)) ids.push(ws.id)
        }
        return ids.sort((a, b) => a - b)
    }
    signal togglePopup(string name)
    color: "transparent"
    implicitHeight: 45

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: root.compact ? 3 : 9
        BarButton {
            transparentStyle: true
            icon: "󰣇"
            foreground: Theme.accent
            tooltip: "Anwendungen öffnen"
            onClicked: SystemStatus.launch(["rofi", "-show", "drun"])
        }
        BarButton {
            transparentStyle: true
            icon: "󰠮"
            foreground: Theme.barMuted
            tooltip: "Scratchpad-Notiz öffnen"
            onClicked: SystemStatus.launch(["kwrite", Quickshell.env("HOME") + "/Notizen/Scratchpad.txt"])
        }
        Rectangle { implicitWidth: 1; implicitHeight: 17; color: Theme.barSeparator }
        Row {
            spacing: 3
            Repeater {
                model: root.workspaceIds
                BarButton {
            transparentStyle: true
                    required property int modelData
                    readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                    implicitWidth: root.compact ? 32 : 40
                    padding: 0
                    text: modelData.toString().padStart(2, "0")
                    selected: root.activeId === modelData
                    foreground: workspace?.urgent ? Theme.amber : selected ? Theme.text : workspace?.toplevels.values.length ? Theme.blue : Theme.barMuted
                    tooltip: "Workspace " + modelData + (workspace?.toplevels.values.length ? " · " + workspace.toplevels.values.length + " Fenster" : "")
                    onClicked: SystemStatus.workspace(modelData)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.selected ? 14 : 3
                        height: 2
                        radius: 1
                        color: parent.selected ? Theme.accent : Theme.barMuted
                        visible: parent.selected || (parent.workspace?.toplevels.values.length ?? 0) > 0
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 240
            Layout.maximumWidth: root.compact ? 180 : 10000
            implicitHeight: 30
            clip: true
            Text {
                anchors.fill: parent
                anchors.leftMargin: 12
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: Theme.barMuted
                style: Text.Raised
                styleColor: Theme.textShadow
                font.family: Theme.font
                font.pixelSize: 11
                elide: Text.ElideRight
                text: {
                    const active = Hyprland.activeToplevel
                    return active && (!root.monitor || active.monitor?.name === root.monitor.name) ? active.title : "DESKTOP"
                }
                textFormat: Text.PlainText
            }
        }
        BarButton {
            transparentStyle: true
            visible: !root.compact && (!!SystemStatus.player || root.preview)
            icon: SystemStatus.player?.isPlaying ? "󰏤" : "󰎈"
            text: SystemStatus.player?.trackTitle ?? (root.preview ? "Midnight City · M83" : "")
            maxTextWidth: Math.min(180, root.width * 0.08)
            foreground: Theme.green
            tooltip: (SystemStatus.player?.trackArtist ?? "") + "\nKlick: Play/Pause · Rechts: Stop · Scrollen: Titel wechseln"
            onClicked: button => {
                const p = SystemStatus.player
                if (!p) return
                if (button === Qt.RightButton) { if (p.canControl) p.stop() }
                else if (p.canTogglePlaying) p.togglePlaying()
            }
            onScrolled: delta => {
                const p = SystemStatus.player
                if (delta > 0 && p?.canGoNext) p.next()
                else if (delta < 0 && p?.canGoPrevious) p.previous()
            }
        }
        BarButton {
            transparentStyle: true
            icon: SystemStatus.notifications.class?.toString().includes("dnd") ? "󰂛" : "󰂚"
            foreground: SystemStatus.notifications.class?.toString().includes("notification") ? Theme.accent : Theme.barMuted
            tooltip: "Benachrichtigungen · Rechtsklick: Nicht stören"
            onClicked: button => SystemStatus.launch(["swaync-client", button === Qt.RightButton ? "-d" : "-t"])
        }
        BarButton {
            transparentStyle: true
            icon: SystemStatus.stats.network.device ? (SystemStatus.stats.network.wifi ? "󰤨" : "󰈀") : "󰤭"
            text: root.compact ? "" : SystemStatus.stats.network.name
            maxTextWidth: 110
            foreground: SystemStatus.stats.network.device ? Theme.green : Theme.accent
            tooltip: SystemStatus.stats.network.name + (SystemStatus.stats.network.signal !== null ? " · " + SystemStatus.stats.network.signal + "%" : "") + "\nKlick: WLAN-IP kopieren · Rechts: Netzwerkeinstellungen"
            onClicked: button => button === Qt.RightButton ? SystemStatus.launch(["qs", "ipc", "call", "settings", "network"]) : SystemStatus.script("wifi_ip")
        }
        Row {
            visible: !root.compact
            spacing: 0
            BarButton {
            transparentStyle: true
                icon: "󰍛"; text: SystemStatus.stats.cpu + "%"; foreground: Theme.barMuted; padding: 8
                tooltip: "CPU-Auslastung · Systemmonitor öffnen"
                onClicked: SystemStatus.script("btop")
            }
            BarButton {
            transparentStyle: true
                icon: "󰘚"; text: SystemStatus.stats.memory + "%"; foreground: Theme.barMuted; padding: 8
                tooltip: "Arbeitsspeicher · " + SystemStatus.stats.memoryDetail
                onClicked: SystemStatus.script("btop")
            }
            BarButton {
            transparentStyle: true
                visible: SystemStatus.stats.temperature !== null
                icon: "󰔏"; text: SystemStatus.stats.temperature + "°"; padding: 8
                foreground: SystemStatus.stats.temperature >= 80 ? Theme.accent : Theme.barMuted
                tooltip: "CPU-Temperatur"
                onClicked: SystemStatus.script("btop")
            }
        }
        VolumeMonitor { id: volume }
        BarButton {
            transparentStyle: true
            icon: volume.icon
            text: volume.muted ? "aus" : volume.volume + "%"
            foreground: volume.muted ? Theme.barMuted : Theme.blue
            tooltip: "Audio · Klick: Mixer · Rechts: Stumm · Scrollen: Lautstärke"
            onClicked: button => button === Qt.RightButton ? SystemStatus.launch(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) : SystemStatus.launch(["pavucontrol"])
            onScrolled: delta => SystemStatus.launch(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", delta > 0 ? "5%+" : "5%-"])
        }
        BarButton {
            transparentStyle: true
            icon: "󰖔"
            foreground: SystemStatus.nightlight.class === "on" ? Theme.amber : Theme.barMuted
            tooltip: SystemStatus.nightlight.class === "on" ? "Nachtlicht an · Ausschalten" : "Nachtlicht aus · Einschalten"
            onClicked: SystemStatus.launch(["sh", Quickshell.env("HOME") + "/.config/hypr/scripts/nightlight.sh", "toggle"])
        }
        BarButton {
            transparentStyle: true
            visible: SystemStatus.stats.battery !== null
            icon: SystemStatus.stats.battery?.status === "Charging" ? "󰂄" : "󰁹"
            text: (SystemStatus.stats.battery?.capacity ?? 0) + "%"
            foreground: (SystemStatus.stats.battery?.capacity ?? 100) < 20 ? Theme.accent : Theme.green
            tooltip: SystemStatus.stats.battery?.status ?? ""
            interactive: false
        }
        Rectangle { implicitWidth: 1; implicitHeight: 17; color: Theme.barSeparator }
        BarButton {
            transparentStyle: true
            text: clock.date.toLocaleString(Qt.locale("de_DE"), root.compact ? "dd.MM.  HH:mm" : "ddd, dd. MMM   HH:mm")
            selected: true
            tooltip: "Kalender öffnen"
            onClicked: root.togglePopup("calendar")
            SystemClock { id: clock; precision: SystemClock.Minutes }
        }
        BarButton {
            transparentStyle: true
            visible: !root.compact
            text: "NY " + SystemStatus.stats.newYork
            foreground: Theme.barMuted
            tooltip: "New York · America/New_York (mit Sommerzeit)"
            interactive: false
        }
        Row {
            spacing: 3
            Repeater {
                model: SystemTray.items
                Item {
                    id: trayIcon
                    required property var modelData
                    width: 28; height: 32
                    BarButton {
            transparentStyle: true
                        anchors.fill: parent
                        IconImage { anchors.centerIn: parent; implicitSize: 17; source: trayIcon.modelData.icon }
                        tooltip: trayIcon.modelData.tooltipTitle || trayIcon.modelData.title
                        onClicked: button => {
                            if ((button === Qt.RightButton || trayIcon.modelData.onlyMenu) && trayIcon.modelData.hasMenu && root.panelWindow) {
                                const pos = trayIcon.mapToItem(root, 0, height)
                                trayIcon.modelData.display(root.panelWindow, pos.x, pos.y)
                            } else if (button === Qt.MiddleButton) trayIcon.modelData.secondaryActivate()
                            else trayIcon.modelData.activate()
                        }
                        onScrolled: delta => trayIcon.modelData.scroll(delta, false)
                    }
                }
            }
        }
        BarButton {
            transparentStyle: true
            icon: "󰒓"
            foreground: Theme.barMuted
            tooltip: "Schnelleinstellungen · Rechtsklick: Alle Einstellungen"
            onClicked: button => SystemStatus.launch(["qs", "ipc", "call", button === Qt.RightButton ? "settings" : "qa", "toggle"])
        }
        BarButton {
            transparentStyle: true
            icon: "󰌾"
            foreground: Theme.barMuted
            tooltip: "Bildschirm sperren"
            onClicked: SystemStatus.script("lock")
        }
        BarButton {
            transparentStyle: true
            icon: "󰐥"
            foreground: Theme.accent
            tooltip: "Sitzung · Sperren, Abmelden, Standby, Ausschalten"
            onClicked: root.togglePopup("power")
        }
    }
}
