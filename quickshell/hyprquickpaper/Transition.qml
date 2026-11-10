import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root
    property real progress: 0
    SequentialAnimation on progress {
        running: true
        PauseAnimation { duration: 100 }
        NumberAnimation { to: 1; duration: 560; easing.type: Easing.InOutCubic }
        PauseAnimation { duration: 100 }
        ScriptAction { script: Qt.quit() }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "hyprquickpaper-transition"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Image {
                anchors.fill: parent
                source: Quickshell.env("HYPRQUICKPAPER_OLD_IMAGE")
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: window.screen.width
                sourceSize.height: window.screen.height
                asynchronous: false
                scale: 1 + root.progress * 0.025
                opacity: 1 - root.progress * 0.2
            }
            Item {
                id: reveal
                anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                width: parent.width * root.progress
                clip: true
                Image {
                    width: window.width
                    height: window.height
                    source: Quickshell.env("HYPRQUICKPAPER_NEW_IMAGE")
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: window.screen.width
                    sourceSize.height: window.screen.height
                    asynchronous: false
                }
                Rectangle {
                    anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                    width: 2
                    color: "#b2ccc4"
                    opacity: Math.sin(root.progress * Math.PI) * 0.22
                }
            }
        }
    }
}
