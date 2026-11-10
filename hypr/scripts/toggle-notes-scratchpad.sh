#!/usr/bin/env bash
set -euo pipefail
note_file="$HOME/Notizen/Scratchpad.txt"
mkdir -p "$(dirname "$note_file")"
touch "$note_file"

# If KWrite is not already on the notes workspace, launch it there first.
if ! hyprctl -j clients | jq -e '.[] | select((.class == "kwrite" or .initialClass == "kwrite" or .class == "org.kde.kwrite" or .initialClass == "org.kde.kwrite") and .workspace.name == "special:notes")' >/dev/null; then
    hyprctl dispatch exec "[workspace special:notes silent] kwrite '$note_file'"
    sleep 0.7
fi
hyprctl dispatch togglespecialworkspace notes
