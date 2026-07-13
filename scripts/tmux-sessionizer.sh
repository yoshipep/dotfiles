#!/usr/bin/env bash

export PATH="$HOME/.fzf/bin:$HOME/.cargo/bin:$PATH"

# tmuxinator reads projects from the first of these that exists
for dir in "$HOME/.config/tmuxinator" "$HOME/.tmuxinator"; do
    [[ -d $dir ]] && config_dir=$dir && break
done

project_names() {
    [[ -z $config_dir ]] && return
    find -L "$config_dir" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) \
        -printf '%f\n' | sed 's/\.ya\?ml$//' | sort
}

# tmuxinator names the session after the project unless the yml overrides it
project_session() {
    local name
    name=$(sed -n 's/^name:[[:space:]]*//p' "$config_dir/$1".y*ml | head -1)
    echo "${name:-$1}"
}

projects=$(project_names)
dirs=$(find -L ~/repos /opt -maxdepth 1 -mindepth 1 -type d; echo "$HOME/scripts"; echo "$HOME/dockers")

if [[ $# -eq 1 ]]; then
    selected=$1
else
    # Projects first, marked with *; plain directories below
    selected=$(printf '%s\n%s\n' \
        "$(echo "$projects" | sed '/./s/^/* /')" "$dirs" | grep . \
        | fzf --tmux --header '* = tmuxinator project')
fi

[[ -z $selected ]] && exit 0

if [[ $selected == '* '* ]]; then
    project=${selected#'* '}
elif [[ -d $selected ]]; then
    # A directory that has a project of the same name is treated as that project
    candidate=$(basename "$selected")
    if echo "$projects" | grep -qxF "$candidate"; then
        project=$candidate
    fi
else
    project=$selected
fi

if [[ -n $project ]]; then
    session=$(project_session "$project")
    session=${session//./_}
    if ! tmux has-session -t="$session" 2>/dev/null; then
        tmuxinator start "$project" --no-attach || exit 1
    fi
else
    session=$(basename "$selected" | tr . _)
    tmux new-session -A -s "$session" -d -c "$selected"
fi

if [[ -z $TMUX ]]; then
    tmux attach -t "$session"
else
    tmux switch-client -t "$session"
fi
