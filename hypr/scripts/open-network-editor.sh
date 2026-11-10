#!/bin/sh

logfile="${XDG_STATE_HOME:-$HOME/.local/state}/network-editor.log"
mkdir -p "$(dirname "$logfile")"

{
    printf '%s\n' "---- $(date) ----"
    if command -v networkmanager_dmenu >/dev/null 2>&1; then
        networkmanager_dmenu --config "$HOME/.config/networkmanager-dmenu/config.ini"
    elif command -v gtk-launch >/dev/null 2>&1; then
        gtk-launch nm-connection-editor.desktop
    else
        nm-connection-editor
    fi
} >>"$logfile" 2>&1 &
