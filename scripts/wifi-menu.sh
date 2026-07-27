#!/usr/bin/env bash
# Wi-Fi picker for Sway: choose a nearby network with fuzzel and connect via
# NetworkManager. Prompts (masked) for a password only if the network needs one.
set -u

ssid=$(nmcli --get-values SSID device wifi list |
	awk 'NF && !seen[$0]++' |
	fuzzel --dmenu --prompt 'Wi-Fi: ') || exit 0
[ -z "$ssid" ] && exit 0

# Connect straight away if it's open or already known; otherwise ask for the key.
nmcli device wifi connect "$ssid" 2>/dev/null && exit 0

pass=$(fuzzel --dmenu --password --prompt "Password for $ssid: " </dev/null) || exit 0
[ -n "$pass" ] && nmcli device wifi connect "$ssid" password "$pass"
