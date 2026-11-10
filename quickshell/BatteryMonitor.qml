import QtQuick
QtObject {
    readonly property bool available: SystemStatus.stats.battery !== null
    readonly property int capacity: SystemStatus.stats.battery?.capacity ?? 0
    readonly property string status: SystemStatus.stats.battery?.status ?? ""
    readonly property string icon: status === "Charging" ? "󰂄" : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.max(0, Math.min(9, Math.floor(capacity / 10)))]
}
