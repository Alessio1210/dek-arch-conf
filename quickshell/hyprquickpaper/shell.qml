pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: main
    visible: !setter.running
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hyprquickpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    property var entries: []
    property var presets: []
    property var packs: []
    property var theme: ({})
    property string directory: ""
    property string currentPath: ""
    property string message: "Bilder werden geladen …"
    property int selectedIndex: 0
    property bool loading: true
    readonly property bool themeMode: true
    readonly property bool gallery: theme.layout === "gallery"
    readonly property color foreground: theme.text ?? "#f4f4f5"
    readonly property color muted: theme.muted ?? "#a3acb7"
    readonly property color accent: theme.accent ?? "#db747e"
    readonly property int duration: Math.max(0, Math.min(800, theme.animation_ms ?? 180))
    readonly property int cardWidth: Math.max(100, Math.min(600, theme.card_width ?? 300))
    readonly property int cardHeight: Math.max(100, Math.min(600, theme.card_height ?? 380))
    readonly property int gap: Math.max(0, Math.min(60, theme.spacing ?? 20))
    readonly property int corners: Math.max(0, Math.min(40, theme.radius ?? 16))
    IpcHandler {
        target: "wallpaper"
        function dismiss(): void { Qt.quit() }
    }

    function reveal() {
        if (gallery) grid.positionViewAtIndex(selectedIndex, GridView.Contain)
        else {
            carousel.positionViewAtIndex(selectedIndex, ListView.Contain)
            const item = carousel.itemAtIndex(selectedIndex)
            if (item) carousel.contentX = item.x + item.width / 2 - carousel.width / 2
        }
    }
    function move(delta) {
        if (!entries.length) return
        selectedIndex = (selectedIndex + delta + entries.length) % entries.length
        reveal()
    }
    function chooseTemplate(preset) {
        theme = preset
        saveTemplate.command = ["python3", Quickshell.shellPath("helper.py"), "template", preset.id]
        saveTemplate.running = true
        Qt.callLater(reveal)
    }
    function apply() {
        if (!entries.length || setter.running || loading) return
        message = "Hintergrund wird gesetzt …"
        const entry = entries[selectedIndex]
        setter.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/SettingsHub/hub-helper.py", "theme", entry.theme]
        setter.running = true
    }
    function applyPack(pack) {
        if (packProcess.running) return
        message = "Design-Paket wird angewendet …"
        packProcess.command = ["python3", Quickshell.shellPath("helper.py"), "pack", pack.id]
        packProcess.running = true
    }
    function reload() {
        if (!catalogue.running) {
            loading = true
            catalogue.command = ["python3", Quickshell.shellPath("helper.py"), "list", themeMode ? "themes" : "wallpapers"]
            catalogue.running = true
        }
    }

    Process {
        id: catalogue
        command: ["python3", Quickshell.shellPath("helper.py"), "list", main.themeMode ? "themes" : "wallpapers"]
        running: true
        stdout: StdioCollector { id: catalogueOutput }
        onExited: (code, status) => {
            main.loading = false
            try {
                const data = JSON.parse(catalogueOutput.text)
                if (code !== 0 || data.error) throw new Error(data.error || "Bilder konnten nicht geladen werden")
                main.entries = data.wallpapers
                main.presets = data.templates
                main.packs = data.packs ?? []
                main.directory = data.directory
                main.currentPath = data.current
                main.theme = data.templates.find(p => p.id === data.template) ?? data.templates[0] ?? ({})
                const current = main.entries.findIndex(p => p.path === data.current)
                main.selectedIndex = current >= 0 ? current : Math.floor(main.entries.length / 2)
                main.message = data.warnings.length ? data.warnings.length + " Bild(er) konnten nicht gelesen werden." : ""
                Qt.callLater(main.reveal)
            } catch (error) { main.message = String(error) }
        }
    }
    Process { id: saveTemplate }
    Process {
        id: packProcess
        stdout: StdioCollector { id: packOutput }
        onExited: (code, status) => {
            try {
                const result = JSON.parse(packOutput.text)
                if (code === 0 && result.ok) Qt.quit()
                else main.message = result.error || "Design-Paket konnte nicht angewendet werden."
            } catch (error) { main.message = "Design-Paket konnte nicht angewendet werden." }
        }
    }
    Process {
        id: setter
        stdout: StdioCollector { id: setterOutput }
        onExited: (code, status) => {
            try {
                const result = JSON.parse(setterOutput.text)
                if (code === 0 && result.ok) Qt.quit()
                else main.message = result.error || "Hintergrund konnte nicht gesetzt werden."
            } catch (error) { main.message = "Hintergrund konnte nicht gesetzt werden." }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: main.theme.background ?? "#d9080a0e"
        Behavior on color { ColorAnimation { duration: main.duration } }
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: main.gallery ? Math.min(parent.width - 48, 1500) : parent.width
            height: main.gallery ? Math.min(parent.height - 48, 840) : parent.height
            color: main.theme.surface ?? "#171b20"
            radius: main.corners + 8
            border.color: main.gallery ? "#32434c56" : "transparent"
            focus: true
            MouseArea { anchors.fill: parent; onClicked: panel.forceActiveFocus() }
            Keys.onPressed: event => {
                const columns = Math.max(1, Math.floor(grid.width / grid.cellWidth))
                switch (event.key) {
                case Qt.Key_Escape: case Qt.Key_W: Qt.quit(); break
                case Qt.Key_Left: case Qt.Key_A: main.move(-1); break
                case Qt.Key_Right: case Qt.Key_D: main.move(1); break
                case Qt.Key_Up: main.move(main.gallery ? -columns : -1); break
                case Qt.Key_Down: main.move(main.gallery ? columns : 1); break
                case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: main.apply(); break
                case Qt.Key_R: main.reload(); break
                case Qt.Key_Tab:
                    if (main.presets.length) main.chooseTemplate(main.presets[(main.presets.findIndex(p => p.id === main.theme.id) + 1) % main.presets.length]);
                    break
                default: return
                }
                event.accepted = true
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.min(32, panel.width * 0.04)
                spacing: 18
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        visible: main.gallery
                        spacing: 5
                        Text { text: "DEIN DESKTOP"; color: main.accent; font.pixelSize: 11; font.letterSpacing: 2 }
                        Text { text: main.themeMode ? "Themes" : "Wallpapers"; color: main.foreground; font.pixelSize: 28; font.weight: Font.DemiBold }
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 6
                        Repeater {
                            model: main.presets
                            Rectangle {
                                required property var modelData
                                width: presetName.implicitWidth + 24; height: 34; radius: 8
                                color: main.theme.id === modelData.id ? main.accent : "#244a5760"
                                Text { id: presetName; anchors.centerIn: parent; text: parent.modelData.name ?? parent.modelData.id; color: main.theme.id === parent.modelData.id ? "#101418" : main.foreground; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; onClicked: { main.chooseTemplate(parent.modelData); panel.forceActiveFocus() } }
                            }
                        }
                        Rectangle {
                            width: 34; height: 34; radius: 8; color: "#244a5760"
                            Text { anchors.centerIn: parent; text: "×"; color: main.foreground; font.pixelSize: 22 }
                            MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
                        }
                    }
                }
                Row {
                    visible: main.packs.length > 0
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: main.packs
                        Rectangle {
                            required property var modelData
                            width: Math.min(220, packLabel.implicitWidth + 74)
                            height: 44
                            radius: 9
                            color: "#244a5760"
                            Image {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 4 }
                                width: 48; source: parent.modelData.preview
                                fillMode: Image.PreserveAspectCrop; asynchronous: true
                            }
                            Text {
                                id: packLabel
                                anchors { left: parent.left; leftMargin: 60; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: parent.modelData.name
                                color: main.foreground; font.pixelSize: 12; elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { main.applyPack(parent.modelData); panel.forceActiveFocus() }
                            }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: main.gallery
                    text: main.directory; color: main.muted; font.pixelSize: 12; elide: Text.ElideMiddle
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ListView {
                        id: carousel
                        anchors.fill: parent
                        visible: !main.gallery
                        model: main.entries
                        orientation: ListView.Horizontal
                        spacing: main.gap
                        leftMargin: Math.max(0, (width - Math.min(main.cardWidth, width * 0.7)) / 2)
                        rightMargin: leftMargin
                        boundsBehavior: Flickable.StopAtBounds
                        preferredHighlightBegin: leftMargin
                        preferredHighlightEnd: width - leftMargin
                        highlightRangeMode: ListView.NoHighlightRange
                        highlightMoveDuration: main.duration
                        Behavior on contentX {
                            enabled: !carousel.dragging && !carousel.flicking && !main.loading
                            NumberAnimation { duration: main.duration; easing.type: Easing.OutCubic }
                        }
                        currentIndex: main.selectedIndex
                        delegate: WallpaperTile {
                            width: Math.min(main.cardWidth, carousel.width * 0.7)
                            height: carousel.height
                            tileHeight: Math.min(main.cardHeight, height - 16)
                        }
                    }
                    GridView {
                        id: grid
                        anchors.fill: parent
                        visible: main.gallery
                        model: main.entries
                        cellWidth: width / Math.max(1, Math.floor(width / (main.cardWidth + main.gap)))
                        cellHeight: main.cardHeight + main.gap
                        currentIndex: main.selectedIndex
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: WallpaperTile {
                            width: grid.cellWidth; height: grid.cellHeight
                            tileHeight: grid.cellHeight - main.gap
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !main.entries.length
                        width: parent.width * 0.8
                        text: main.loading ? "Vorschaubilder werden vorbereitet …" : "Noch keine Wallpapers.\nLege Bilder in den Ordner oben und drücke R."
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: main.muted; font.pixelSize: 18
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: main.entries[main.selectedIndex]?.name ?? ""
                            color: main.foreground; font.pixelSize: 17; elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: main.themeMode ? "Komplettes Desktop-Theme · Hintergrund und Farben" : main.entries[main.selectedIndex]?.gif ? "GIF · Hyprpaper verwendet das erste Bild" : main.entries.length + " Bilder · für alle Monitore"
                            color: main.muted; font.pixelSize: 11; elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        width: applyText.implicitWidth + 36; height: 42; radius: 10
                        color: main.accent; opacity: setter.running || !main.entries.length ? 0.4 : 1
                        Text { id: applyText; anchors.centerIn: parent; text: main.themeMode ? "Theme anwenden  ↵" : "Hintergrund setzen  ↵"; color: "#101418"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; onClicked: main.apply() }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: main.message || "← → / A D  Auswahl     Enter / Doppelklick  Setzen     Tab  Layout     R  Neu laden     Esc  Schließen"
                    color: main.message ? main.accent : main.muted; font.pixelSize: 11; wrapMode: Text.WordWrap
                }
            }
        }
    }
    component WallpaperTile: Item {
        id: tile
        required property var modelData
        required property int index
        property real tileHeight: height
        readonly property bool selected: main.selectedIndex === index
        readonly property real centerDistance: Math.abs(x - carousel.contentX + width / 2 - carousel.width / 2)
        readonly property real fraction: Math.min(1, centerDistance / Math.max(1, carousel.width / 2))
        readonly property real carouselScale: 0.36 + 0.64 * (1 - fraction * fraction * (3 - 2 * fraction))
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - (main.gallery ? main.gap : 0)
            height: tile.tileHeight
            scale: main.gallery ? 1 : tile.carouselScale
            opacity: main.gallery ? (tile.selected ? 1 : 0.8) : 1
            Behavior on scale { NumberAnimation { duration: main.duration; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: main.duration } }
            color: "#0b1015"
            radius: main.corners
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: 3
                source: tile.modelData.preview
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 900
                sourceSize.height: 600
            }
            AnimatedImage {
                anchors.fill: parent; anchors.margins: 3
                source: tile.modelData.gif && tile.selected ? tile.modelData.url : ""
                visible: tile.modelData.gif && tile.selected && status === AnimatedImage.Ready
                playing: visible
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Rectangle {
                anchors.fill: parent; color: "transparent"; radius: main.corners
                border.width: tile.selected ? 3 : 1
                border.color: tile.selected ? main.accent : "#40505b66"
            }
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 3 }
                visible: main.gallery
                height: 34; color: "#c9080c10"
                Text { anchors.fill: parent; anchors.margins: 9; text: tile.modelData.name; color: main.foreground; elide: Text.ElideRight; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
            }
            Text { anchors { top: parent.top; right: parent.right; margins: 12 } text: tile.modelData.path === main.currentPath ? "AKTUELL" : ""; color: main.accent; font.pixelSize: 10; font.bold: true }
            MouseArea {
                anchors.fill: parent
                onClicked: { main.selectedIndex = tile.index; panel.forceActiveFocus(); main.reveal() }
                onDoubleClicked: { main.selectedIndex = tile.index; main.apply() }
                onWheel: wheel => { main.move(wheel.angleDelta.y < 0 ? 1 : -1); wheel.accepted = true }
            }
        }
    }
}
