#!/bin/sh
set -eu
directory="$HOME/.config/quickshell/hyprquickpaper"
export HYPRQUICKPAPER_MODE=themes
exec quickshell --no-duplicate --path "$directory"
