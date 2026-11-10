#!/bin/sh

set -eu

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-nightlight.pid"
LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-nightlight.lock"
LOG="${XDG_RUNTIME_DIR:-/tmp}/hypr-nightlight.log"
CONFIG="$HOME/.config/hypr/hyprsunset.conf"

if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCKFILE"
    flock 9
fi

if [ -x /usr/bin/hyprsunset ]; then
    HYPRSUNSET=/usr/bin/hyprsunset
elif [ -x "$HOME/.local/bin/hyprsunset" ]; then
    HYPRSUNSET="$HOME/.local/bin/hyprsunset"
else
    HYPRSUNSET="$(command -v hyprsunset 2>/dev/null || true)"
fi

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "Night Light" -t 2000 "$1" >/dev/null 2>&1 || true
}

is_running() {
    [ -f "$PIDFILE" ] || return 1
    pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
    [ -n "$pid" ] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    state=$(awk '{print $3}' "/proc/$pid/stat" 2>/dev/null) || return 1
    [ "$state" != "Z" ]
}

stop() {
    command -v hyprctl >/dev/null 2>&1 && hyprctl hyprsunset identity >/dev/null 2>&1 || true
    pkill -TERM -x hyprsunset 2>/dev/null || true
    i=0
    while pgrep -x hyprsunset >/dev/null 2>&1 && [ "$i" -lt 20 ]; do
        sleep 0.1
        i=$((i + 1))
    done
    pkill -KILL -x hyprsunset 2>/dev/null || true
    pkill -TERM -x wlsunset 2>/dev/null || true
    rm -f "$PIDFILE"
}

start() {
    if [ -z "$HYPRSUNSET" ]; then
        notify "hyprsunset is not installed"
        exit 1
    fi
    stop
    setsid "$HYPRSUNSET" >"$LOG" 2>&1 9>&- &
    sleep 0.6
    pid=$(pgrep -n -x hyprsunset 2>/dev/null) || pid=""
    if [ -z "$pid" ]; then
        rm -f "$PIDFILE"
        notify "Night Light could not be started"
        exit 1
    fi
    echo "$pid" >"$PIDFILE"
    notify "Night Light on"
}

case "${1:-toggle}" in
    start | on)
        start
        ;;
    stop | off)
        stop
        notify "Night Light off"
        ;;
    toggle)
        if is_running; then
            stop
            notify "Night Light off"
        else
            start
        fi
        ;;
    autostart)
        if ! is_running; then
            start
        fi
        ;;
    status)
        if is_running; then
            echo "on"
        else
            echo "off"
        fi
        ;;
    waybar)
        if is_running; then
            printf '{"text":"☾","tooltip":"Night Light on - click to turn off","class":"on"}\n'
        else
            printf '{"text":"☀","tooltip":"Night Light off - click to turn on","class":"off"}\n'
        fi
        ;;
    *)
        echo "usage: $0 {start|stop|toggle|autostart|status|waybar}" >&2
        exit 2
        ;;
esac
