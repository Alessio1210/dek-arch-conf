import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../.." as Desktop

Flickable {
    id: page
    clip: true
    contentHeight: content.implicitHeight + 40
    property var presets: []
    property string feedback: ""
    Process {
        command: ["python3", Quickshell.shellPath("SettingsHub/hub-helper.py"), "list"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.presets = JSON.parse(text) } catch (error) { page.feedback = String(error) } } }
    }
    Process {
        id: apply
        stdout: StdioCollector { id: output }
        onExited: (code, status) => page.feedback = code === 0 ? "Theme angewendet." : output.text
    }
    ColumnLayout {
        id: content
        width: parent.width - 20
        spacing: 18
        Text { text: "Themes"; color: Theme.text; font.pixelSize: 25 }
        Text { Layout.fillWidth: true; text: "Jede Auswahl wechselt immer Hintergrund und komplette Desktop-Farben gemeinsam."; color: Theme.textDim; wrapMode: Text.WordWrap }
        Flow {
            Layout.fillWidth: true
            spacing: 12
            Repeater {
                model: page.presets
                Rectangle {
                    required property var modelData
                    width: 200; height: 110; radius: 12
                    color: modelData.colors.raised
                    border.width: 2
                    border.color: Desktop.Theme.palette._preset === modelData.id || (!Desktop.Theme.palette._preset && modelData.id === "rose") ? modelData.colors.accent : modelData.colors.line
                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 16
                        Row {
                            spacing: 8
                            Repeater {
                                model: [modelData.colors.accent, modelData.colors.green, modelData.colors.blue, modelData.colors.text]
                                Rectangle { required property string modelData; width: 25; height: 25; radius: 12; color: modelData }
                            }
                        }
                        Text { text: modelData.name; color: modelData.colors.text; font.pixelSize: 12 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            apply.command = ["python3", Quickshell.shellPath("SettingsHub/hub-helper.py"), "theme", parent.modelData.id]
                            apply.running = true
                        }
                    }
                }
            }
        }
        HubButton {
            text: "Komplette Themes als Karussell öffnen"
            onClicked: Quickshell.execDetached(["sh", Quickshell.env("HOME") + "/.config/quickshell/hyprquickpaper/start.sh", "--themes"])
        }
        Text { text: page.feedback; color: Theme.accent }
    }
}
