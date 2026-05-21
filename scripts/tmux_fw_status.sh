#!/bin/sh

h=$(cat /etc/.fw_host_status 2>/dev/null | tr -d '[:space:]')
case "$h" in
    1) tmux set -gq @fw_status "1" ;;
    0) tmux set -gq @fw_status "0" ;;
    *) tmux set -gq @fw_status "?" ;;
esac

d=$(cat /etc/.fw_docker_status 2>/dev/null | tr -d '[:space:]')
case "$d" in
    1) tmux set -gq @fw_docker_status "1" ;;
    0) tmux set -gq @fw_docker_status "0" ;;
    *) tmux set -gq @fw_docker_status "?" ;;
esac

tmux refresh-client -S
