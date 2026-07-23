#!/usr/bin/env bash
# tmux status segments. When waybar is running (Sway desktop — it already shows
# host/ip/firewall/docker/clock) the host/ip and fw/docker/time extensions
# collapse to nothing, leaving a minimal bar; on TTY/SSH (no waybar) the full set
# is shown. Called from status-left/right via #(). Emits literal text + #[...]
# tmux colors only — #{...}/% are NOT re-expanded inside #() output, so host, ip,
# fw/docker state and time are computed here.

side="${1:-right}"

# waybar up -> minimal: emit nothing, keep only the static session/cwd
pgrep -x waybar >/dev/null 2>&1 && exit 0

sep='#[fg=#504945]│'

fw_glyph() {
    case "$(tr -d '[:space:]' < "$1" 2>/dev/null)" in
        1) printf '#[fg=#fb4934]󰀂' ;;
        0) printf '#[fg=#00d75f]󰒄' ;;
        *) printf '#[fg=#fe8019]󰛵' ;;
    esac
}

case "$side" in
    left)
        printf ' %s #[fg=#ebdbb2,nobold]%s %s #[fg=#ebdbb2,nobold]%s' \
            "$sep" "$(hostname -s)" "$sep" "$(hostname -I | awk '{print $1}')"
        ;;
    right)
        printf '%s %s %s %s #[fg=#ebdbb2]%s' \
            "$sep" "$(fw_glyph /etc/.fw_host_status)" "$(fw_glyph /etc/.fw_docker_status)" \
            "$sep" "$(date +%H:%M)"
        ;;
esac
