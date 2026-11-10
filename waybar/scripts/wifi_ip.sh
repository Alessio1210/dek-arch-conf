#!/usr/bin/env bash

set -euo pipefail

iface="$(nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$2 == "wifi" && $3 == "connected" {print $1; exit}')"

if [[ -z "${iface:-}" ]]; then
    notify-send "WLAN IP" "Keine aktive WLAN-Verbindung"
    exit 0
fi

ips="$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | paste -sd ', ' -)"

if [[ -z "${ips:-}" ]]; then
    notify-send "WLAN IP" "${iface}: keine IPv4-Adresse"
else
    printf '%s' "$ips" | wl-copy
    notify-send "WLAN IP copied" "${iface}: ${ips}"
fi
