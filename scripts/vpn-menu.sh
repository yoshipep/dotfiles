#!/usr/bin/env bash
# Mullvad relay picker for Sway: choose a location with fuzzel, set it as the
# relay and (re)connect.
#
# Run by `net vprelay` via VPN_MENU_CMD, not from waybar -- it CONNECTS (`mullvad
# connect` below), and the firewall's vpn switch is what opens the holes a tunnel
# needs. Called directly with that switch off, the relay is set and the connect fails.
#
# EXIT STATUS IS PART OF THE INTERFACE: `net vprelay` flips the switch on BEFORE
# running this and needs to know whether to leave it that way.
#   0    relay chosen, client asked to connect
#   130  cancelled -- nothing was set or attempted
#   1    relay chosen, but setting it or connecting failed
# 130 matters most: this used to exit 0 on cancel too, so pressing Escape was
# indistinguishable from success -- with the switch already on and no tunnel, nothing
# egresses, so a cancel silently took the machine off the network. 130 because that's
# what a shell reports for SIGINT.
set -u

# `mullvad relay list` is a tab-indented tree: country / city / server. Keep the city
# level -- countries alone are too coarse, per-server a wall of hostnames. The trailing
# "[cc city]" carries the codes `relay set location` needs.
sel=$(mullvad relay list | awk '
	/^[^[:space:]]/ {
		country = $0
		code = $0; sub(/.*\(/, "", code); sub(/\).*/, "", code)
		sub(/ *\(.*/, "", country)
		next
	}
	/^\t[^\t]/ {
		line = $0; sub(/^\t/, "", line)
		city = line; sub(/ *\(.*/, "", city)
		ccode = line; sub(/.*\(/, "", ccode); sub(/\).*/, "", ccode)
		printf "%s / %s [%s %s]\n", country, city, code, ccode
	}
# --log-level=error: fuzzel writes several lines about fonts/outputs/version to stderr
# on every launch -- invisible from a waybar click, not from `net vprelay`. Silences
# info, not failure.
' | fuzzel --dmenu --log-level=error --prompt 'VPN relay: ') || exit 130
[ -z "$sel" ] && exit 130

loc=${sel##*[}
loc=${loc%]}

# $loc is "<country> <city>" -- two arguments, must stay unquoted.
# shellcheck disable=SC2086
if mullvad relay set location $loc && mullvad connect; then
	notify-send 'Mullvad' "Relay: ${sel%% [*}"
	rc=0
else
	# Not 130: a relay WAS chosen and attempted, it just failed. `net vprelay` holds the
	# switch on here, same as `net vpon` on a failed connect -- only a cancel rolls back.
	notify-send 'Mullvad' "Failed to set relay: ${sel%% [*}"
	rc=1
fi

pkill -RTMIN+11 waybar
exit "$rc"
