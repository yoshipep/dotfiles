# Linux console? No icon font there. Inside tmux $TERM is tmux-256color, so ask the
# client for its real terminal. Read by .p10k.zsh and the eza alias below.
if [[ $TERM == linux ]] || { [[ -n $TMUX ]] && [[ $(tmux display-message -p -t "$TMUX_PANE" '#{client_termname}' 2>/dev/null) == linux ]]; }; then
  IS_LINUX_CONSOLE=1
fi

# p10k's cached instant prompt is whatever the last session drew (usually the
# desktop one, with icons), so skip it on the console.
if [[ -z $IS_LINUX_CONSOLE && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
	zsh-autosuggestions
)

[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh
export FZF_DEFAULT_OPTS='--layout=reverse-list'

if [[ -f /usr/share/virtualenvwrapper/virtualenvwrapper_lazy.sh ]]; then
	source /usr/share/virtualenvwrapper/virtualenvwrapper_lazy.sh
elif [[ -f /usr/share/virtualenvwrapper/virtualenvwrapper.sh ]]; then
	source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
fi

# Tool-backed aliases are defined only when the tool exists, so a box without
# them (e.g. a locked corporate machine with no installs) keeps its working core
# commands instead of shadowing them with a missing binary.
if command -v bat >/dev/null 2>&1; then
	BAT_CMD="bat"
	export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | $BAT_CMD -p -lman'"
	alias cat="$BAT_CMD"
	alias catnp="$BAT_CMD --paging=never"
fi

if command -v eza >/dev/null 2>&1; then
	if [[ -n $IS_LINUX_CONSOLE ]]; then alias ls='eza -g --long --header --git'
	else alias ls='eza -g --long --header --icons --git'; fi
fi

command -v nvim >/dev/null 2>&1 && alias vim='nvim'
alias c='clear'
alias q='exit'
alias gdb='gdb -q'
alias uu='sudo apt update && sudo apt upgrade -y'
alias python='python3'
alias ipy='ipython --no-confirm-exit --pprint --colors=NoColor --autocall=1'
alias ht='htop'
alias mkcd='function _mkcd() { mkdir -p "$1" && cd "$1" }; _mkcd'
alias findf='function _findf() { find . -type f -name "$1" 2>/dev/null; }; _findf'
alias findd='function _findd() { find . -type d -name "$1" 2>/dev/null; }; _findd'
alias cpv='function _cpv() { cp "$1" "$2" && vim "$2"; }; _cpv'
alias create_patch='function _patch() { diff -u "$1" "$2" > "$3"; }; _patch'
alias bdiff='function _diff() { diff --suppress-common-lines --color=always -y <(xxd "$1") <(xxd "$2"); }; _diff'
alias g='git'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias gotmp='cd $(mktemp -d)'
# A function, not an alias: localoptions only restores nullglob inside one.
clatex() {
	setopt localoptions nullglob
	rm -f *.acn *.aux *.fdb_latexmk *.fls *.glo *.ist *.log *.out *.synctex.gz *.toc
}

alias rc='reset && clear'
alias lzd='lazydocker'
alias sphinx-serve='sphinx-serve.sh'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

bindkey '^U' backward-kill-line
