import QtQuick
QtObject {
    readonly property int memPercentage: SystemStatus.stats.memory
    readonly property string icon: "󰍛"
}
