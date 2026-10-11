export LANG=en_US.UTF-8

# Safe on all WMs/DEs — fixes Java AWT on tiling WMs
export _JAVA_AWT_WM_NONREPARENTING=1

# Wayland-only vars — only set when the session type is actually Wayland
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export SDL_VIDEODRIVER=wayland
    export QT_QPA_PLATFORM=wayland
fi
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/scripts:/usr/local/go/bin:$HOME/go/bin:$PATH"
# Every nested zsh (tmux, scripts, sudo -E) re-runs this and would prepend the same
# entries again; -U keeps the first occurrence of each.
typeset -U path
# CPU count without forking nproc: same source (this process's affinity mask),
# parsed from a list like "0-3,8". .zshenv runs for every zsh, scripts included.
_n=0
if [[ -r /proc/self/status ]]; then
	for _r in ${(s:,:)${${(M)${(f)"$(</proc/self/status)"}:#Cpus_allowed_list:*}##*[[:space:]]}}; do
		_n=$(( _n + ${_r#*-} - ${_r%-*} + 1 ))
	done
fi
(( _n )) || _n=$(nproc)
export MAKEFLAGS="-j$_n"
unset _n _r
export WORKON_HOME="$HOME/.virtualenvs"
export CMAKE_EXPORT_COMPILE_COMMANDS=ON
# VMs live in the privileged libvirt instance; make virsh/virt-manager target it
export LIBVIRT_DEFAULT_URI=qemu:///system
# Prefer neovim, fall back to vim then vi, so EDITOR is valid on any box.
for _ed in nvim vim vi; do
	command -v "$_ed" >/dev/null 2>&1 && { export EDITOR="$_ed"; break; }
done
unset _ed

# Load Rust/Cargo environment (installed via rustup)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
