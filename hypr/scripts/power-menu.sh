#!/usr/bin/env bash

set -euo pipefail

choice="$(printf '%s\n' \
    '  Lock' \
    '  Logout' \
    '  Reboot' \
    '  Shutdown' \
    | rofi -dmenu \
        -i \
        -p 'Power' \
        -theme /home/alessio/.config/hypr/power-menu.rasi)"

confirm() {
    local action="$1"

    [[ "$(printf '%s\n' 'No' 'Yes' \
        | rofi -dmenu \
            -i \
            -p "$action?" \
            -theme /home/alessio/.config/hypr/power-menu.rasi)" == "Yes" ]]
}

case "$choice" in
    '  Lock')
        hyprlock -c /home/alessio/.config/hypr/hyprlock.conf
        ;;
    '  Logout')
        confirm "Logout" && hyprctl dispatch exit
        ;;
    '  Reboot')
        confirm "Reboot" && systemctl reboot
        ;;
    '  Shutdown')
        confirm "Shutdown" && systemctl poweroff
        ;;
esac
