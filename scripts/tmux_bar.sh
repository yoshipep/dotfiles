#!/usr/bin/env bash
# tmux status segments. When waybar is running (Sway desktop — it already shows
# host/ip/firewall/docker/clock) the host/ip and fw/docker/time extensions
# collapse to nothing, leaving a minimal bar; on TTY/SSH (no waybar) the full set
# is shown. Called from status-left/right via #(). Emits literal text + #[...]
# tmux colors only — #{...}/% are NOT re-expanded inside #() output, so host, ip,
# fw/docker state and time are computed here.

side="${1:-right}"
# The client's TERM (#{client_termname} in .tmux.conf): the Linux console has no
# icon font, so there the glyphs become short coloured text.
console=0; [ "${2:-}" = linux ] && console=1

# waybar up -> minimal: emit nothing, keep only the static session/cwd. Not for a
# client on the Linux console: waybar runs on the desktop's VT, not on this one.
[ "$console" = 1 ] || { pgrep -x waybar >/dev/null 2>&1 && exit 0; }

sep='#[fg=#504945]│'

fw_glyph() {
    local v
    v=$(tr -d '[:space:]' 2>/dev/null < "$1")
    if [ "$console" = 1 ]; then
        case "$v" in
            1) printf '#[fg=#fb4934]%s:on' "$2" ;;
            0) printf '#[fg=#00d75f]%s:off' "$2" ;;
            *) printf '#[fg=#fe8019]%s:?' "$2" ;;
        esac
        return
    fi
    case "$v" in
        1) printf '#[fg=#fb4934]󰀂' ;;
        0) printf '#[fg=#00d75f]󰒄' ;;
        *) printf '#[fg=#fe8019]󰛵' ;;
    esac
}

# Same three states and colours as waybar_vpn_status.sh, from the same files. No
# /etc/vpn.conf means no vpn on this machine: show nothing, as waybar does.
vpn_glyph() {
    local vpn tun col g t
    [ -r /etc/vpn.conf ] || return 0
    vpn=$(sed -n 's/^vpn=//p' /run/firewall.state 2>/dev/null | tr -d '[:space:]')
    tun=$(sed -n 's/^tunnelled=//p' /run/firewall.state 2>/dev/null | tr -d '[:space:]')
    if [ "$tun" = 1 ]; then col='#00d75f'; g='󰦝'; t=on
    elif [ "$vpn" = 1 ]; then col='#fe8019'; g='󰦞'; t=wait   # switch on, no tunnel: nothing egresses
    else col='#fb4934'; g='󰦞'; t=off; fi
    if [ "$console" = 1 ]; then printf '#[fg=%s]vpn:%s' "$col" "$t"
    else printf '#[fg=%s]%s' "$col" "$g"; fi
}

case "$side" in
    left)
        printf ' %s #[fg=#ebdbb2,nobold]%s %s #[fg=#ebdbb2,nobold]%s' \
            "$sep" "$(hostname -s)" "$sep" "$(hostname -I | awk '{print $1}')"
        ;;
    right)
        vpn=$(vpn_glyph)
        printf '%s %s%s %s %s #[fg=#ebdbb2]%s' \
            "$sep" "${vpn:+$vpn }" "$(fw_glyph /etc/.fw_host_status net)" "$(fw_glyph /etc/.fw_docker_status dock)" \
            "$sep" "$(date +%H:%M)"
        ;;
esac
