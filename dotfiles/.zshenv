export LANG=en_US.UTF-8

# Safe on all WMs/DEs — fixes Java AWT on tiling WMs
export _JAVA_AWT_WM_NONREPARENTING=1

# Wayland-only vars — only set when the session type is actually Wayland
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export SDL_VIDEODRIVER=wayland
    export QT_QPA_PLATFORM=wayland
fi
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/scripts:/usr/local/go/bin:$HOME/go/bin:$PATH"
export MAKEFLAGS="-j$(nproc)"
export WORKON_HOME="$HOME/.virtualenvs"
export CMAKE_EXPORT_COMPILE_COMMANDS=ON
export EDITOR="/opt/neovim/bin/nvim"

# Load Rust/Cargo environment (installed via rustup)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
