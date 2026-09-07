#!/usr/bin/env bash
# Waybar VPN status — provider neutral.
#
# Connection state is read from the kernel, not from any VPN client: it checks
# whether the default route leaves through a tunnel device, identified by device
# TYPE (WireGuard or tun/tap) rather than by interface name. That works for any
# WireGuard- or OpenVPN-based provider without the repo knowing which one.
#
# This module RUNS NOTHING and TAKES NO CLICKS. It only displays.
#
# Connecting, disconnecting and changing relay all have to flip the firewall's vpn switch,
# which needs root — /etc/firewall.sh is 700 root:root — and a click has no terminal to
# type a password into. So all three are terminal commands: `net vpon`, `net vprelay`,
# `net vpoff`. Clicking the icon does nothing at all, same as the firewall and docker
# modules, which have never had click actions.
#
# It reads exactly one thing out of /etc/vpn.conf -- VPN_STATUS_CMD, to name the relay in
# the tooltip. The commands that DO something (VPN_UP_CMD / VPN_DOWN_CMD / VPN_MENU_CMD)
# belong to scripts/net and are never run from here.
#
# Returns JSON: {"text": "icon", "class": "on|off", "tooltip": "..."}
# With no config file the module emits empty text, which makes waybar hide it —
# so machines without a VPN show nothing rather than a permanently red icon.

CONF="/etc/vpn.conf"

# Its presence is what says "there is a vpn on this machine" -- absent, the module emits
# empty text and waybar hides it.
if [ ! -r "$CONF" ]; then
    echo '{"text": "", "tooltip": ""}'
    exit 0
fi

# Sourced for ONE optional key, VPN_STATUS_CMD, used to name the relay in the tooltip.
# Safe to source as your user: the file is 644 root:root, so only root can put anything in
# it. None of the other VPN_* commands are run from here -- those belong to scripts/net.
# shellcheck source=/dev/null
. "$CONF" 2>/dev/null

# Device actually carrying traffic — the only one that matters, since a tunnel that
# is up but not routing anything is not protecting anything.
#
# Prefer what firewall.sh wrote down. It decides this with a WireGuard handshake check
# that needs root, which this module cannot do on a five-second poll as your user. It
# matters: with Mullvad a plain route lookup answers with the WAN even while connected,
# because the client routes via ip rules rather than the main table's default route.
#
# Falling back to the route lookup keeps the module working on a machine that has no
# firewall.sh — it is just less accurate for those clients.
STATE=/run/firewall.state
dev=""
if [ -r "$STATE" ]; then
    # shellcheck source=/dev/null
    . "$STATE" 2>/dev/null
    [ "${tunnelled:-0}" = "1" ] && dev="${path:-}"
fi
[ -n "$dev" ] || dev=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP '\bdev \K\S+' | head -1)

# Must stay in step with is_tunnel in firewall.sh -- same test, same reasoning.
#
# The presence of a tun_flags file is NOT enough. libvirt gives every vm nic a TAP
# device (vnet0, vnet1) carrying the same file, so the existence check counted each
# running vm as a tunnel and the tooltip below announced "up: vnet0 vnet1". IFF_TUN
# is 0x1 and IFF_TAP is 0x2; openvpn's point-to-point device sets the former,
# libvirt the latter.
is_tunnel() {
    local f
    [ -n "$1" ] || return 1
    if [ -r "/sys/class/net/$1/tun_flags" ]; then
        f=$(cat "/sys/class/net/$1/tun_flags")
        (( f & 0x1 ))
        return $?
    fi
    grep -qs '^DEVTYPE=wireguard$' "/sys/class/net/$1/uevent"    # WireGuard
}

# Every tunnel that is up, not just the one holding the default route. With more
# than one VPN configured, a tunnel can be up while carrying only part of the
# traffic (split tunnel / policy routing) — the icon reports the default route,
# the tooltip lists the rest so that case is visible instead of silent.
active_tunnels() {
    for p in /sys/class/net/*; do
        [ "$(cat "$p/operstate" 2>/dev/null)" = "down" ] && continue
        is_tunnel "${p##*/}" && printf '%s ' "${p##*/}"
    done
}

# No argument handling at all, and none wanted. This module takes no actions -- exactly
# like the firewall and docker modules -- so a click does nothing and says nothing.
#
# Any argument a stale waybar config still passes (toggle, menu, gui) is simply ignored:
# execution falls straight through to the status output below, and waybar discards stdout
# from a click handler. So an out-of-date config degrades to silence rather than to an
# error or a stray notification.

up=$(active_tunnels)
up=${up% }

# Anything interpolated into the JSON below gets its quotes, backslashes and newlines
# stripped. VPN_STATUS_CMD output is the only untrusted-shaped input here -- a relay name
# with a quote in it would otherwise produce malformed JSON and blank the whole module.
clean() { printf '%s' "$1" | tr -d '"\\\n\r' | cut -c1-80; }

# What the client calls the thing it is connected to. Provider-specific, so it is a command
# in /etc/vpn.conf rather than logic here -- same arrangement as the other VPN_* commands.
# A device name means nothing to a human; "Madrid, Spain" is the thing worth hovering for.
# Unset simply falls back to the device, which is what this always used to show.
relay=""
if [ -n "${VPN_STATUS_CMD:-}" ]; then
    relay=$(clean "$(eval "$VPN_STATUS_CMD" 2>/dev/null | head -1)")
fi

# THREE states, because the vpn switch made a third one real and it is the one you most
# need to see: the switch is on, no tunnel is up, and therefore NOTHING egresses at all.
# Reporting that as plain "off" would describe a working machine, when in fact it is dark.
#
# `vpn` comes from /run/firewall.state, so this needs no privileges. Where that file is
# absent (a machine with no firewall.sh) `vpn` is unset and the old two-state behaviour
# stands: tunnelled or not.
if [ "${vpn:-}" = "1" ] && [ "${tunnelled:-0}" != "1" ]; then
    # Matches the wording `net status` uses for the same state, on purpose -- one vocabulary
    # across the bar and the terminal.
    icon="󰦞" ; class="pending"
    tooltip="VPN on, no tunnel up — nothing can egress\nConnect, or 'net vpoff' to go out via the wan"
elif is_tunnel "$dev"; then
    # No device name when the relay is known: it is noise next to a location, and
    # `net status` already prints the device on its `path` row for when it matters.
    # With no VPN_STATUS_CMD the device IS the only thing there is to say, so it stays.
    icon="󰦝" ; class="on"
    tooltip="VPN: ${relay:-connected via ${dev}}"
else
    icon="󰦞" ; class="off"
    tooltip="VPN off — traffic leaves directly${dev:+ via ${dev}}"
fi

# Mention other tunnels only when they are not just the default-route one.
[ -n "$up" ] && [ "$up" != "$dev" ] && tooltip="${tooltip} — up: ${up}"

echo "{\"text\": \"${icon}\", \"class\": \"${class}\", \"tooltip\": \"${tooltip}\"}"
