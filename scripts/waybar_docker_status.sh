#!/bin/bash
# Waybar firewall docker status
# Returns JSON: {"text": "icon", "class": "on|off|unknown", "tooltip": "..."}

d=$(cat /etc/.fw_docker_status 2>/dev/null | tr -d '[:space:]')

case "$d" in
    1) icon="󰀂" ; class="off" ; tooltip="Docker internet: ON"  ;;
    0) icon="󰒄" ; class="on"  ; tooltip="Docker internet: OFF" ;;
    *) icon="󰛵" ; class="unknown" ; tooltip="Docker internet: unknown" ;;
esac

echo "{\"text\": \"${icon}\", \"class\": \"${class}\", \"tooltip\": \"${tooltip}\"}"
