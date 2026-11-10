pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string mode: "calendar"
    property string pendingAction: ""
    property date today: new Date()
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    signal closeRequested()
    color: Theme.surface
    radius: 20
    border.color: Theme.line
    implicitWidth: 360
    implicitHeight: mode === "calendar" ? 370 : 350
    function shiftMonth(delta) { month = new Date(month.getFullYear(), month.getMonth() + delta, 1) }
    function execute(action) {
        if (action === "lock") { closeRequested(); SystemStatus.script("lock"); return }
        if (pendingAction !== action) { pendingAction = action; return }
        closeRequested()
        if (action === "logout") SystemStatus.logout()
        else SystemStatus.script(action)
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            Column {
                spacing: 5
                Text { text: root.mode === "calendar" ? "DEINE ZEIT" : "FEIERABEND?"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
                Text {
                    text: root.mode === "calendar" ? root.month.toLocaleDateString(Qt.locale("de_DE"), "MMMM yyyy") : "Deine Sitzung"
                    color: Theme.text; font.family: Theme.font; font.pixelSize: 19; font.weight: Font.Medium
                }
            }
            Item { Layout.fillWidth: true }
            BarButton { icon: "󰅖"; tooltip: "Schließen · Esc"; onClicked: root.closeRequested() }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
        ColumnLayout {
            visible: root.mode === "calendar"
            Layout.fillWidth: true
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                BarButton { text: "‹"; onClicked: root.shiftMonth(-1) }
                Item { Layout.fillWidth: true }
                BarButton { text: "Heute"; foreground: Theme.muted; onClicked: root.month = new Date(root.today.getFullYear(), root.today.getMonth(), 1) }
                Item { Layout.fillWidth: true }
                BarButton { text: "›"; onClicked: root.shiftMonth(1) }
            }
            GridLayout {
                columns: 7
                Layout.fillWidth: true
                rowSpacing: 3
                columnSpacing: 3
                Repeater {
                    model: ["MO", "DI", "MI", "DO", "FR", "SA", "SO"]
                    Text {
                        required property string modelData
                        text: modelData; color: Theme.muted; font.family: Theme.font; font.pixelSize: 9
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        Layout.bottomMargin: 6
                    }
                }
                Repeater {
                    model: 42
                    Rectangle {
                        required property int index
                        readonly property int offset: (root.month.getDay() + 6) % 7
                        readonly property date date: new Date(root.month.getFullYear(), root.month.getMonth(), index - offset + 1)
                        readonly property bool isToday: date.toDateString() === root.today.toDateString()
                        Layout.fillWidth: true
                        implicitHeight: 27
                        radius: 8
                        color: isToday ? Theme.accent : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: parent.date.getDate()
                            color: parent.isToday ? "#171214" : parent.date.getMonth() === root.month.getMonth() ? Theme.text : "#4b5562"
                            font.family: Theme.font; font.pixelSize: 11
                        }
                    }
                }
            }
        }
        ColumnLayout {
            visible: root.mode === "power"
            Layout.fillWidth: true
            spacing: 7
            Repeater {
                model: [
                    {name: "Sperren", action: "lock", icon: "󰌾", key: "L"},
                    {name: "Abmelden", action: "logout", icon: "󰍃", key: ""},
                    {name: "Standby", action: "suspend", icon: "󰤄", key: ""},
                    {name: "Ausschalten", action: "shutdown", icon: "󰐥", key: ""}
                ]
                BarButton {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 39
                    icon: modelData.icon
                    text: root.pendingAction === modelData.action ? "Bestätigen: " + modelData.name : modelData.name
                    selected: true
                    foreground: root.pendingAction === modelData.action ? Theme.accent : Theme.text
                    onClicked: root.execute(modelData.action)
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.pendingAction ? "Zum Bestätigen erneut klicken." : "Ein ruhiger Desktop. Ein guter Abschluss."
                color: Theme.muted; font.family: Theme.font; font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
        Item { Layout.fillHeight: true }
    }
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
}
