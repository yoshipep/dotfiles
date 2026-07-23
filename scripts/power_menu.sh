#!/bin/bash

set -euo pipefail

choice=$(printf "Lock\nReboot\nShutdown" | fuzzel --dmenu --prompt "" --width 150 --lines 3)

case "$choice" in
    Lock)     swaylock -c 000000 ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
