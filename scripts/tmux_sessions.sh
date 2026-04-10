#!/bin/sh

current="$1"
idx=0
tmux list-sessions -F '#{session_name}' 2>/dev/null | while read -r name; do
    # Check if any pane in this session is running ssh
    is_ssh=$(tmux list-panes -t "$name" -F '#{pane_current_command}' 2>/dev/null | grep -q '^ssh$' && echo 1)

    if [ "$name" = "$current" ] && [ "$is_ssh" = "1" ]; then
        printf '#[fg=#282828,bg=#fb4934,bold] %d:%s #[default] ' "$idx" "$name"
    elif [ "$name" = "$current" ]; then
        printf '#[fg=#282828,bg=#d79921,bold] %d:%s #[default] ' "$idx" "$name"
    elif [ "$is_ssh" = "1" ]; then
        printf '#[fg=#fb4934] %d:%s #[default] ' "$idx" "$name"
    else
        printf '#[fg=#928374] %d:%s #[default] ' "$idx" "$name"
    fi
    idx=$((idx + 1))
done
