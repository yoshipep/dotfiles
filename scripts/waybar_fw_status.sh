#!/bin/bash
# Waybar firewall host status
# Returns JSON: {"text": "icon", "class": "on|off|unknown", "tooltip": "..."}

h=$(cat /etc/.fw_host_status 2>/dev/null | tr -d '[:space:]')

case "$h" in
    1) icon="󰀂" ; class="off" ; tooltip="Host internet: ON"  ;;
    0) icon="󰒄" ; class="on"  ; tooltip="Host internet: OFF" ;;
    *) icon="󰛵" ; class="unknown" ; tooltip="Host internet: unknown" ;;
esac

echo "{\"text\": \"${icon}\", \"class\": \"${class}\", \"tooltip\": \"${tooltip}\"}"
