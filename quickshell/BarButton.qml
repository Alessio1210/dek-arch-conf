import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property string tooltip: ""
    property color foreground: Theme.text
    property bool transparentStyle: false
    property bool selected: false
    property bool interactive: true
    property int maxTextWidth: 1000
    property int padding: 11
    signal clicked(int button)
    signal scrolled(int delta)
    implicitWidth: content.width + padding * 2
    implicitHeight: 32
    radius: 10
    color: selected ? (transparentStyle ? Theme.barSelected : Theme.raised)
                    : mouse.containsMouse && interactive ? (transparentStyle ? Theme.barHover : Theme.hover)
                    : "transparent"
    scale: mouse.pressed && interactive ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Row {
        id: content
        anchors.centerIn: parent
        spacing: root.icon && root.text ? 7 : 0
        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.foreground
            style: root.transparentStyle ? Text.Raised : Text.Normal
            styleColor: Theme.textShadow
            font.family: Theme.icons
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.text !== ""
            text: root.text
            width: Math.min(implicitWidth, root.maxTextWidth)
            elide: Text.ElideRight
            color: root.foreground
            style: root.transparentStyle ? Text.Raised : Text.Normal
            styleColor: Theme.textShadow
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => { if (root.interactive) root.clicked(event.button) }
        onWheel: event => { if (root.interactive) root.scrolled(event.angleDelta.y) }
    }
    ToolTip {
        visible: mouse.containsMouse && root.tooltip !== ""
        delay: 600
        timeout: 7000
        text: root.tooltip
        padding: 12
        contentItem: Text {
            text: root.tooltip
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 11
            textFormat: Text.PlainText
        }
        background: Rectangle { color: Theme.raised; radius: 10; border.color: Theme.line }
    }
}
