pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Singleton {
    id: root
    property var stats: ({cpu: 0, memory: 0, memoryDetail: "", temperature: null, battery: null,
                          brightness: null, network: {name: "…", device: "", wifi: false, signal: null}, newYork: "--:--"})
    property string solana: "SOL · …"
    property var nightlight: ({text: "☀", tooltip: "Nachtlicht", class: "off"})
    property var notifications: ({class: "none", text: "0"})
    readonly property var player: {
        const players = Mpris.players.values
        return players.find(p => p.isPlaying) ?? players[0] ?? null
    }
    function launch(args) { Quickshell.execDetached(args) }
    function script(name) { launch(["bash", Quickshell.env("HOME") + "/.config/waybar/scripts/" + name + ".sh"]) }
    function workspace(id) {
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + id + " })" : "workspace " + id)
    }
    function logout() {
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit")
    }
    function parse(line, fallback) {
        try { return JSON.parse(line) } catch (error) { console.warn("Status: invalid JSON:", error); return fallback }
    }
    Process {
        id: sampler
        running: true
        command: ["python3", Quickshell.shellPath("scripts/status.py")]
        stdout: SplitParser { onRead: line => root.stats = root.parse(line, root.stats) }
        onExited: (code, status) => restartSampler.restart()
    }
    Timer { id: restartSampler; interval: 5000; onTriggered: sampler.running = true }
    Process {
        id: price
        running: true
        command: ["bash", Quickshell.env("HOME") + "/.config/waybar/scripts/solana_price.sh"]
        stdout: SplitParser { onRead: line => root.solana = line.replace("1 SOL = ", "SOL · ").replace("unavailable", "—") }
    }
    Timer { interval: 600000; running: true; repeat: true; onTriggered: price.running = true }
    Process {
        id: night
        running: true
        command: ["sh", Quickshell.env("HOME") + "/.config/hypr/scripts/nightlight.sh", "waybar"]
        stdout: SplitParser { onRead: line => root.nightlight = root.parse(line, root.nightlight) }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: night.running = true }
    Process {
        id: notificationWatch
        running: true
        command: ["sh", "-c", "command -v swaync-client >/dev/null 2>&1 && exec swaync-client -swb"]
        stdout: SplitParser { onRead: line => root.notifications = root.parse(line, root.notifications) }
        onExited: (code, status) => restartNotifications.restart()
    }
    Timer { id: restartNotifications; interval: 15000; onTriggered: notificationWatch.running = true }
}
