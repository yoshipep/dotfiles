#!/usr/bin/env bash
# Waybar IP: the host's primary LAN IP = the source address of the default route.
# Using the default-route source ignores docker0/bridges/virtual interfaces — the
# old "first global address" grabbed docker0's 172.17.0.1 when Docker was running.
# Falls back to the first non-virtual global address if there is no default route.
ip=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
[ -z "$ip" ] && ip=$(ip -4 -o addr show scope global |
	grep -vE ' (docker|br-|veth|virbr|vm|tun|tap)' |
	grep -oP '(?<=inet )\d+\.\d+\.\d+\.\d+' | head -1)
printf '{"text":"%s","tooltip":"IP address"}' "$ip"
