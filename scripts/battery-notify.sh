#!/usr/bin/env bash
# Instant charger/battery notifications, event-driven off udevadm's power_supply
# feed -- waybar's battery module (dotfiles/.config/waybar/config) only samples
# every 30s, too slow to catch a charger unplug or a level crossing as it happens.
# exec_always re-runs this on every `swaymsg reload`; killing the old udevadm
# monitor breaks its pipe, which ends that instance's loop and lets it exit --
# no need to hunt down and kill the old script process itself.
set -u
pkill -f "udevadm monitor --udev --subsystem-match=power_supply" 2>/dev/null

CRIT_LEVEL=20

read_state() {
	capacity=0
	online=0
	for type_file in /sys/class/power_supply/*/type; do
		dir=$(dirname "$type_file")
		case "$(cat "$type_file" 2>/dev/null)" in
		Battery)
			[ -r "$dir/capacity" ] && capacity=$(cat "$dir/capacity")
			;;
		Mains | USB)
			[ "$(cat "$dir/online" 2>/dev/null)" = 1 ] && online=1
			;;
		esac
	done
}

read_state
prev_online=$online

# Don't retroactively alert if it's already below the threshold when this
# starts -- only alert on the crossing that happens from here on.
notified=0
[ "$capacity" -le "$CRIT_LEVEL" ] && notified=1

udevadm monitor --udev --subsystem-match=power_supply 2>/dev/null | while read -r _; do
	read_state

	if [ "$online" != "$prev_online" ]; then
		if [ "$online" = 1 ]; then
			notify-send 'Battery' 'Charger connected'
			notified=0
		else
			notify-send 'Battery' 'Charger disconnected'
		fi
		prev_online=$online
	fi

	if [ "$online" = 0 ] && [ "$capacity" -le "$CRIT_LEVEL" ] && [ "$notified" = 0 ]; then
		notify-send -u critical 'Battery' "Battery at ${capacity}% -- plug in the charger"
		notified=1
	fi
done
