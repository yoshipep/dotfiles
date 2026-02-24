if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
	git
	zsh-autosuggestions
	rsync
)

source $ZSH/oh-my-zsh.sh
export LANG=en_US.UTF-8
TEXLIVE_BIN="$(command ls -d /usr/local/texlive/*/bin/x86_64-linux 2>/dev/null | sort -V | tail -n1)"
# Load Rust/Cargo environment (installed via rustup)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/scripts:${TEXLIVE_BIN}:$PATH"
export FZF_DEFAULT_OPTS='--layout=reverse-list'
export MAKEFLAGS="-j$(nproc)"
# Detect bat/batcat binary (Ubuntu 24.04+ uses 'bat', older uses 'batcat')
if command -v batcat &> /dev/null; then
	BAT_CMD="batcat"
elif command -v bat &> /dev/null; then
	BAT_CMD="bat"
else
	BAT_CMD="cat"
fi
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | $BAT_CMD -p -lman'"
export WORKON_HOME="$HOME/.virtualenvs"
export CMAKE_EXPORT_COMPILE_COMMANDS=ON
export EDITOR="/opt/neovim/bin/nvim"
# Load virtualenvwrapper if installed (FULL mode only)
[[ -f /usr/share/virtualenvwrapper/virtualenvwrapper.sh ]] && source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
alias cat="$BAT_CMD"
alias catnp="$BAT_CMD --paging=never"
alias ls='eza -g --long --header --icons --git'
alias vim="/opt/neovim/bin/nvim"
alias c='clear'
alias d="cd $HOME/Desktop"
alias q='exit'
alias gdb='gdb -q'
alias gdbm='gdb-multiarch -q'
alias uu='sudo apt update; sudo apt upgrade -y'
alias python='python3'
alias ipy='ipython --no-confirm-exit --pprint --colors=NoColor --autocall=1'
alias ht='htop'
alias mkcd='function _mkcd() { mkdir "$1" && cd "$1" }; _mkcd'
alias findf='function _findf() { find . -type f -name "$1" 2>/dev/null; }; _findf'
alias findd='function _findd() { find . -type d -name "$1" 2>/dev/null; }; _findd'
alias cpv='function _cpv() { cp "$1" "$2" && vim "$2"; }; _cpv'
alias create_patch='function _patch() { diff -u "$1" "$2" > "$3"; }; _patch'
alias bdiff='function _diff() { diff --suppress-common-lines --color=always -y <(xxd "$1") <(xxd "$2"); }; _diff'
alias g='git'
alias gotmp="cd $(mktemp -d)"
alias clatex='setopt localoptions nullglob; rm -f *.acn *.aux *.fdb_latexmk *.fls *.glo *.ist *.log *.out *.synctex.gz *.toc'
alias rc='reset && clear'
alias lzd='lazydocker'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

fpath+=${ZDOTDIR:-~}/.zsh_functions
