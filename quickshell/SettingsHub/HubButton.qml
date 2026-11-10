import QtQuick
Rectangle {
    id: root
    property string text: ""
    property bool selected: false
    signal clicked()
    implicitWidth: caption.implicitWidth + 28
    implicitHeight: 38
    radius: 8
    color: selected ? Theme.accent : mouse.containsMouse ? Theme.trackBg : Theme.bgCard
    border.color: selected ? Theme.accent : Theme.border
    Text { id: caption; anchors.centerIn: parent; text: root.text; color: root.selected ? "#111519" : Theme.text; font.family: Theme.fontFamily; font.pixelSize: 12 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
