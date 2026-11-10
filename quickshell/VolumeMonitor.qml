import QtQuick
import Quickshell.Services.Pipewire
QtObject {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string icon: muted || volume === 0 ? "󰖁" : volume < 33 ? "󰕿" : volume < 66 ? "󰖀" : "󰕾"
    readonly property PwObjectTracker tracker: PwObjectTracker { objects: root.sink ? [root.sink] : [] }
}
