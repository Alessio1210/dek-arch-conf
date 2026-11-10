#!/usr/bin/env bash
set -euo pipefail
config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Daemonize returns after the configuration has loaded successfully.
quickshell --no-duplicate --daemonize --path "$config_dir"
# Only retire Waybar once Quickshell's launch has succeeded.
pkill -x waybar || true
