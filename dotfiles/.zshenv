export LANG=en_US.UTF-8
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/scripts:/usr/local/go/bin:$HOME/go/bin:$PATH"
export MAKEFLAGS="-j$(nproc)"
export WORKON_HOME="$HOME/.virtualenvs"
export CMAKE_EXPORT_COMPILE_COMMANDS=ON
export EDITOR="/opt/neovim/bin/nvim"

# Load Rust/Cargo environment (installed via rustup)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
