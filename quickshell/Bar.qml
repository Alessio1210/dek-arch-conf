pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property var modelData
            property string popup: ""
            screen: modelData
            color: "transparent"
            implicitHeight: 45
            anchors { top: true; left: true; right: true }
            margins { top: 10; left: 10; right: 10 }
            exclusiveZone: implicitHeight + 13
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top
            BarContent {
                anchors.fill: parent
                shellScreen: bar.modelData
                panelWindow: bar
                onTogglePopup: name => bar.popup = bar.popup === name ? "" : name
            }
            LazyLoader {
                active: bar.popup !== ""
                PanelWindow {
                    screen: bar.modelData
                    color: "transparent"
                    implicitWidth: 360
                    implicitHeight: content.implicitHeight
                    anchors { top: true; right: true }
                    margins { top: bar.implicitHeight + 20; right: 10 }
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.namespace: "quickshell-menu"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                    PopupContent {
                        id: content
                        anchors.fill: parent
                        focus: true
                        mode: bar.popup
                        onModeChanged: pendingAction = ""
                        onCloseRequested: bar.popup = ""
                        Keys.onEscapePressed: bar.popup = ""
                    }
                }
            }
        }
    }
}
