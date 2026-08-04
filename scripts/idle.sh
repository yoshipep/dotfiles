#!/usr/bin/env bash
# Start swayidle, restarting any existing instance first. Called from the sway
# config with `exec_always` so a `swaymsg reload` always picks up the current lock
# command — plain `exec swayidle` runs only at login and would keep an old instance
# locking with the previous locker. The pkill guard avoids stacking duplicates.
pkill -x swayidle
exec swayidle -w \
	timeout 300 "$HOME/scripts/lock.sh" \
	timeout 420 'swaymsg "output * power off"' \
	resume 'swaymsg "output * power on"' \
	before-sleep "$HOME/scripts/lock.sh -d"
