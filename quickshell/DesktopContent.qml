pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: 510
    implicitHeight: 590
    property var todos: []
    function saveTodos() { todoFile.setText(JSON.stringify(todos)) }
    function addTodo() {
        const title = todoInput.text.trim()
        if (!title) return
        todos = [...todos, { title: title, done: false }]
        todoInput.text = ""
        saveTodos()
    }
    FileView {
        id: todoFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/todos.json"
        printErrors: false
        onLoaded: {
            try { root.todos = JSON.parse(text()) }
            catch (error) { root.todos = [] }
        }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    ColumnLayout {
        anchors.fill: parent
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Rectangle { implicitWidth: 20; implicitHeight: 2; radius: 1; color: Theme.accent }
            Text { text: "SLOW DOWN. STAY CURIOUS."; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
        }
        Text {
            Layout.alignment: Qt.AlignRight
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 102
            font.weight: Font.ExtraLight
            font.letterSpacing: -7
        }
        Text {
            Layout.alignment: Qt.AlignRight
            text: clock.date.toLocaleDateString(Qt.locale("de_DE"), "dddd, dd. MMMM yyyy")
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 15
        }
        Text {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: 6
            text: "i hope peace"
            color: Theme.accent
            font.family: "DejaVu Serif"
            font.italic: true
            font.pixelSize: 38
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Text { text: "HEUTE"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
                Item { Layout.fillWidth: true }
                Text { text: root.todos.filter(todo => !todo.done).length + " OFFEN"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextInput {
                    id: todoInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    onAccepted: root.addTodo()
                    Text { anchors.fill: parent; text: "Aufgabe hinzufügen…"; color: Theme.muted; font: parent.font; visible: !parent.text && !parent.activeFocus; verticalAlignment: Text.AlignVCenter }
                }
                Rectangle {
                    width: 28; height: 28; radius: 14; color: Theme.raised
                    Text { anchors.centerIn: parent; text: "+"; color: Theme.accent; font.pixelSize: 20 }
                    MouseArea { anchors.fill: parent; onClicked: root.addTodo() }
                }
            }
            Repeater {
                model: root.todos
                RowLayout {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 9
                    Rectangle {
                        width: 15; height: 15; radius: 5
                        color: modelData.done ? Theme.accent : "transparent"
                        border.width: 1; border.color: modelData.done ? Theme.accent : Theme.muted
                        Text { anchors.centerIn: parent; text: "✓"; color: "#101316"; font.pixelSize: 11; visible: modelData.done }
                        MouseArea { anchors.fill: parent; onClicked: { const copy = root.todos.slice(); copy[index] = { title: modelData.title, done: !modelData.done }; root.todos = copy; root.saveTodos() } }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.title
                        color: modelData.done ? Theme.muted : Theme.text
                        font.family: Theme.font; font.pixelSize: 13
                        elide: Text.ElideRight
                        font.strikeout: modelData.done
                    }
                    Text {
                        text: "×"; color: Theme.muted; font.pixelSize: 17
                        MouseArea { anchors.fill: parent; onClicked: { const copy = root.todos.slice(); copy.splice(index, 1); root.todos = copy; root.saveTodos() } }
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.topMargin: 12; implicitHeight: 1; color: Theme.line }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 20
            Repeater {
                model: [
                    {label: "MEMORY", value: SystemStatus.stats.memory + "%", show: true},
                    {label: "BATTERY", value: (SystemStatus.stats.battery?.capacity ?? 0) + "%", show: SystemStatus.stats.battery !== null},
                    {label: "VOLUME", value: volume.muted ? "MUTE" : volume.volume + "%", show: true},
                    {label: "LIGHT", value: SystemStatus.stats.brightness + "%", show: SystemStatus.stats.brightness !== null}
                ]
                Column {
                    required property var modelData
                    visible: modelData.show
                    spacing: 7
                    Text { text: parent.modelData.label; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1.5 }
                    Text { text: parent.modelData.value; color: Theme.text; font.family: Theme.font; font.pixelSize: 22; font.weight: Font.Light }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
    VolumeMonitor { id: volume }
}
