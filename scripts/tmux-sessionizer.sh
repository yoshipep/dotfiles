#!/usr/bin/env bash

export PATH="$HOME/.fzf/bin:$HOME/.cargo/bin:$PATH"

repos=$(find ~/repos -maxdepth 1 -mindepth 1 -type d)
opt=$(find /opt -maxdepth 1 -mindepth 1 -type d)
scripts=$HOME/scripts

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(echo -e "$repos\n$opt\n$scripts" | fzf --tmux)
fi

if [[ -z $selected ]]; then
    exit 0
fi

session=$(basename "$selected" | tr . _)

tmux new-session -A -s "$session" -d -c "$selected"

if [[ -z $TMUX ]]; then
    tmux attach -t "$session"
else
    tmux switch-client -t "$session"
fi
