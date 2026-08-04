#!/usr/bin/env bash
# Date & time menu for Sway: pick an action with fuzzel, apply it with timedatectl.
# Bound to a left click on the waybar clock. Setting the clock is privileged, so
# timedatectl asks over D-Bus and the mate-polkit agent puts up the dialog.
set -u

for dep in fuzzel timedatectl notify-send; do
	command -v "$dep" >/dev/null || {
		notify-send -u critical 'Clock' "time-menu.sh: $dep is not installed"
		exit 1
	}
done

# waybar forks this with no terminal, so stderr goes nowhere. A dismissed polkit
# dialog exits non-zero with nothing on it — hence the ${err:-cancelled} fallback.
run() {
	if ! err=$(timedatectl "$@" 2>&1 >/dev/null); then
		notify-send -u critical 'Clock' "$* failed: ${err:-cancelled}"
		exit 1
	fi
}

ntp=$(timedatectl show -p NTP --value)
tz=$(timedatectl show -p Timezone --value)
[ "$ntp" = yes ] && sync='on' || sync='off'

choice=$(printf '%s\n' \
	'Set date & time' \
	"Set time zone  ($tz)" \
	"Automatic sync ($sync)" |
	fuzzel --dmenu --prompt 'Clock: ') || exit 0

case "$choice" in
'Set date & time')
	# systemd-timesyncd owns the clock while NTP is on and timedatectl refuses
	# set-time outright, so deal with that first instead of failing at the end.
	if [ "$ntp" = yes ]; then
		answer=$(printf 'Yes\nNo\n' | fuzzel --dmenu \
			--prompt 'Automatic sync is on. Turn it off? ') || exit 0
		[ "$answer" = Yes ] || exit 0
		run set-ntp false
	fi

	# fuzzel hands back whatever was typed, so the current stamp is offered as a
	# starting point to edit. date(1) parses it, which means "14:30", "tomorrow
	# 09:00" and "2026-08-04 12:00:00" all work.
	input=$(date '+%Y-%m-%d %H:%M:%S' | fuzzel --dmenu --prompt 'Set to: ') || exit 0
	[ -z "$input" ] && exit 0

	if ! stamp=$(date -d "$input" '+%Y-%m-%d %H:%M:%S' 2>/dev/null); then
		notify-send -u critical 'Clock' "Not a date I understand: $input"
		exit 1
	fi

	run set-time "$stamp"
	notify-send 'Clock' "Clock set to $stamp"
	;;
'Set time zone'*)
	new=$(timedatectl list-timezones | fuzzel --dmenu --prompt 'Time zone: ') || exit 0
	[ -z "$new" ] && exit 0
	run set-timezone "$new"
	notify-send 'Clock' "Time zone set to $new"
	;;
'Automatic sync'*)
	if [ "$ntp" = yes ]; then
		run set-ntp false
		notify-send 'Clock' 'Automatic sync off — the clock is yours to set'
	else
		# Turning sync back on discards any hand-set time at the next poll.
		run set-ntp true
		notify-send 'Clock' 'Automatic sync on — systemd-timesyncd owns the clock'
	fi
	;;
esac
