import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import ".."
Flickable {
    contentHeight: content.implicitHeight + 40
    clip: true
    ColumnLayout {
        id: content
        width: parent.width - 20
        spacing: 20
        Text { text: "Darstellung"; color: Theme.text; font.pixelSize: 25 }
        Text { text: "Einstellungsfenster und Schnelleinstellungen"; color: Theme.textDim }
        Text { text: "Deckkraft · " + Math.round(Theme.bgAlpha * 100) + "%"; color: Theme.text }
        Controls.Slider {
            Layout.fillWidth: true
            from: 0.3; to: 1; value: Theme.bgAlpha
            onMoved: Theme.setHub("bgAlpha", value)
        }
        Text { text: "Rundung · " + Theme.radius + " px"; color: Theme.text }
        Controls.Slider {
            Layout.fillWidth: true
            from: 0; to: 30; stepSize: 1; value: Theme.radius
            onMoved: Theme.setHub("radius", value)
        }
        HubButton { text: Theme.clickOutsideClose ? "Klick außerhalb schließt · An" : "Klick außerhalb schließt · Aus"; onClicked: Theme.setHub("clickOutsideClose", !Theme.clickOutsideClose) }
        HubButton { text: Theme.hideSettingsIcons ? "Symbole anzeigen" : "Symbole ausblenden"; onClicked: Theme.setHub("hideSettingsIcons", !Theme.hideSettingsIcons) }
        HubButton { text: "Darstellung zurücksetzen"; onClicked: Theme.resetHub() }
    }
}
