pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            implicitWidth: Math.min(510, modelData.width - 80)
            implicitHeight: 590
            anchors { top: true; right: true }
            margins { top: 180; right: 55 }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-desktop"
            // Keep the widget behind normal windows, but allow input when the desktop is exposed.
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            DesktopContent { anchors.fill: parent }
        }
    }
}
