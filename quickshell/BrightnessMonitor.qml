import QtQuick
QtObject {
    readonly property bool available: SystemStatus.stats.brightness !== null
    readonly property int brightness: SystemStatus.stats.brightness ?? 0
}
