pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: workspacePanel
            required property var modelData
            screen: modelData
            implicitWidth: 64
            implicitHeight: 64
            color: "transparent"
            anchors { bottom: true; right: true }
            margins { right: 55; bottom: 55 }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-workspace"
            WlrLayershell.layer: WlrLayer.Bottom
            mask: Region {}
            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Theme.surface
                border.color: Theme.line
                Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 18 } width: 2; radius: 1; color: Theme.accent }
                Text {
                    anchors.centerIn: parent
                    text: (Hyprland.monitorFor(workspacePanel.modelData)?.activeWorkspace?.id ?? 1).toString().padStart(2, "0")
                    color: Theme.text
                    font.family: Theme.font
                    font.weight: Font.Light
                    font.pixelSize: 26
                }
            }
        }
    }
}
