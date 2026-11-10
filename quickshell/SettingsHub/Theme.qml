pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".." as Desktop

QtObject {
    id: root
    property int radius: 10
    property real tiltStrength: 7
    property real bgAlpha: 0.72
    property bool hideSettingsIcons: false
    property bool clickOutsideClose: true
    readonly property string fontFamily: Desktop.Theme.font
    readonly property string iconFont: Desktop.Theme.icons
    readonly property int animFast: 120
    readonly property int animMed: 180
    readonly property int animSlow: 280
    readonly property int textSizeTitle: 18
    readonly property int textSizeSection: 15
    readonly property int textSizeGroup: 12
    readonly property int textSizeBody: 11
    readonly property int textSizeSmall: 10
    readonly property color bg: alpha(Desktop.Theme.surface, bgAlpha)
    readonly property color bgCard: Desktop.Theme.raised
    readonly property color bgPanel: Desktop.Theme.surface
    readonly property color text: Desktop.Theme.text
    readonly property color textDim: Desktop.Theme.muted
    readonly property color textFaint: Desktop.Theme.muted
    readonly property color accent: Desktop.Theme.palette._preset ? Desktop.Theme.accent : "#c6d7d4"
    readonly property color accentSolid: accent
    readonly property color accent2: Desktop.Theme.blue
    readonly property color border: Desktop.Theme.line
    readonly property color borderAccent: Desktop.Theme.accent
    readonly property color danger: "#ed7373"
    readonly property color ok: Desktop.Theme.green
    readonly property color trackBg: Desktop.Theme.hover
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function setHub(key, value) {
        if (["radius", "tiltStrength", "bgAlpha", "hideSettingsIcons", "clickOutsideClose"].includes(key)) {
            root[key] = value
            saveTimer.restart()
        }
    }
    function resetHub() {
        radius = 10; tiltStrength = 7; bgAlpha = 0.72
        hideSettingsIcons = false; clickOutsideClose = true
        saveTimer.restart()
    }
    property Timer saveTimer: Timer {
        interval: 250
        onTriggered: store.setText(JSON.stringify({radius: root.radius, tiltStrength: root.tiltStrength,
            bgAlpha: root.bgAlpha, hideSettingsIcons: root.hideSettingsIcons, clickOutsideClose: root.clickOutsideClose}))
    }
    property FileView store: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/state/hub-appearance.json"
        printErrors: false
        onLoaded: {
            try {
                const value = JSON.parse(text())
                root.radius = Math.max(0, Math.min(30, value.radius ?? 10))
                root.tiltStrength = Math.max(0, Math.min(12, value.tiltStrength ?? 7))
                root.bgAlpha = Math.max(0.3, Math.min(1, value.bgAlpha ?? 0.72))
                root.hideSettingsIcons = value.hideSettingsIcons === true
                root.clickOutsideClose = value.clickOutsideClose !== false
            } catch (error) { console.warn(error) }
        }
    }
}
