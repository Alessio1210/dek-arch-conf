pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
QtObject {
    id: root
    property var palette: ({})
    property FileView paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/state/palette.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: root.palette = ({})
        onLoaded: {
            try { root.palette = JSON.parse(text()) }
            catch (error) { console.warn("Theme:", error) }
        }
    }
    // Transparent taskbar: only hovered/active controls get a light glass tint.
    readonly property color barSelected: "#66343b44"
    readonly property color barHover: "#88343b44"
    readonly property color barMuted: "#c1c9d2"
    readonly property color barSeparator: "#45ffffff"
    readonly property color textShadow: "#d9000000"
    readonly property color surface: palette.surface ?? "#f20d1014"
    readonly property color raised: palette.raised ?? "#191e25"
    readonly property color hover: palette.hover ?? "#282f38"
    readonly property color line: palette.line ?? "#29323b"
    readonly property color text: palette.text ?? "#eee9e2"
    readonly property color muted: palette.muted ?? "#8d99a7"
    readonly property color accent: palette.accent ?? "#d47b76"
    readonly property color green: palette.green ?? "#a3c9b2"
    readonly property color blue: palette.blue ?? "#a8c7df"
    readonly property color amber: "#e5c18c"
    readonly property string font: "JetBrains Mono"
    readonly property string icons: "JetBrainsMono Nerd Font"
}
