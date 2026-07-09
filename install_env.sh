#!/bin/bash

INSTALL="sudo apt install -y"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect distro (ubuntu or debian)
DISTRO=$(. /etc/os-release && echo "$ID")

removeSnap() {
	if [[ "$DISTRO" != "ubuntu" ]]; then
		echo "[*] Snap removal not supported on $DISTRO, skipping."
		return
	fi
	echo "[!] Do you want to remove snap from the system?"
	echo "    This will remove all snap packages, snapd, and prevent reinstallation."
	read -p "    Remove snap? (y/N): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "[*] Skipping snap removal."
		return
	fi

	echo "[!] Starting snap removal process..."

	echo "[1/6] Checking installed snaps..."
	snap list 2>/dev/null || true
	echo

	echo "[2/6] Removing all snap packages..."
	SNAPS=$(snap list 2>/dev/null | awk 'NR>1 {print $1}')
	if [ -n "$SNAPS" ]; then
		for snap_pkg in $SNAPS; do
			echo "  [-] Removing snap: $snap_pkg"
			sudo snap remove --purge "$snap_pkg" 2>/dev/null || true
		done
	else
		echo "  [*] No snap packages found"
	fi
	echo

	echo "[3/6] Stopping and disabling snapd services..."
	sudo systemctl stop snapd.service 2>/dev/null || true
	sudo systemctl stop snapd.socket 2>/dev/null || true
	sudo systemctl stop snapd.seeded.service 2>/dev/null || true
	sudo systemctl disable snapd.service 2>/dev/null || true
	sudo systemctl disable snapd.socket 2>/dev/null || true
	sudo systemctl disable snapd.seeded.service 2>/dev/null || true
	echo

	echo "[4/6] Removing snapd packages..."
	sudo apt-get purge -y snapd gnome-software-plugin-snap 2>/dev/null || true
	sudo apt-get autoremove -y || true
	echo

	echo "[5/6] Cleaning up snap directories..."
	sudo rm -rf /snap
	sudo rm -rf /var/snap
	sudo rm -rf /var/lib/snapd
	sudo rm -rf /var/cache/snapd
	sudo rm -rf /usr/lib/snapd
	rm -rf ~/snap
	echo "  [*] Directories removed"
	echo

	echo "[6/6] Preventing snap from being reinstalled..."
	sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null << 'EOF'
# Prevent snap from being installed
Package: snapd
Pin: release a=*
Pin-Priority: -1

Package: gnome-software-plugin-snap
Pin: release a=*
Pin-Priority: -1
EOF
	echo "  [*] Created /etc/apt/preferences.d/nosnap.pref"
	echo

	echo "[+] Snap has been completely removed from the system!"
	echo "[+] Snap will not be reinstalled automatically."
	echo
}

# ============================================================================
# PACKAGE COMPONENTS
#
# checkPackages() below is a thin wrapper preserving the original FULL/MINIMAL
# order. Each install* function is self-contained so it can also be selected
# individually by the component menu. syspkgs-* are apt-only (Debian/Ubuntu) by
# design; the user-space toolchain/tool components work on any distro (and
# assume the needed system -dev libs are already present when apt isn't used).
# ============================================================================

# apt: core system packages (Debian/Ubuntu only). Root required.
installSyspkgsCore() {
	echo "[!] Installing core system packages (apt)..."
	if [[ "$DISTRO" == "ubuntu" ]]; then
		$INSTALL software-properties-common
		sudo add-apt-repository -y ppa:git-core/ppa
	fi
	sudo apt update
	sudo apt upgrade -y

	local PYTHON_VENV="python$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')-venv"
	local COMMON_PKGS=(
		build-essential git curl wget
		python3-pip pipx "$PYTHON_VENV" python3-pynvim
		htop libclang-dev
		wl-clipboard xclip flameshot
		shellcheck tmux tmuxinator universal-ctags
		libssl-dev pkg-config
		cmake libfreetype-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev
		unzip fontconfig
	)
	$INSTALL "${COMMON_PKGS[@]}"
}

# apt: full-mode-only system packages (texlive, gdb build-deps, java, ulogd2...). Root required.
installSyspkgsFull() {
	echo "[!] Installing full-mode system packages (apt)..."
	if [[ "$DISTRO" == "ubuntu" ]]; then
		sudo add-apt-repository -y ppa:phoerious/keepassxc
		sudo apt update
	fi
	local openjdk=$(apt-cache search openjdk | awk '{print $1}' | grep -oP '^openjdk-\d{1,2}-jdk$' | sort -V | tail -n 1)
	local FULL_PKGS=(
		keepassxc perl gawk socat
		python3-virtualenvwrapper ipython3
		libmpfr-dev libgmp-dev libmpc-dev
		flex bison autoconf automake
		libreadline-dev libncurses-dev python3-dev
		libexpat-dev zlib1g-dev libbabeltrace-dev libipt-dev
		ulogd2 ca-certificates gnupg texlive-full
		"$openjdk"
	)
	$INSTALL "${FULL_PKGS[@]}"
}

# pipx: Python CLI tools + pinned clangd/clang-format. User-space.
# clangd/clang-format are pinned here (PyPI wheels bundle the real native LLVM
# binaries) instead of apt, so C/C++ LSP + formatting are reproducible across
# distros. Neovim formats via clangd (CocAction), and clangd embeds clang-format;
# apt ships wildly varying versions (e.g. clangd 14 on Ubuntu 22.04, which can't
# parse newer .clang-format keys like SortUsingDeclarations: LexicographicNumeric).
# ~/.local/bin is ahead of /usr/bin on PATH (.zshenv), so coc-clangd picks these up.
# Bump LLVM_PIN to upgrade (keep clangd and clang-format on the same version).
installPipxTools() {
	echo "[!] Installing pipx tools (clangd/clang-format pinned)..."
	local LLVM_PIN="19.1.7"
	pipx install autopep8 isort "clangd==${LLVM_PIN}" "clang-format==${LLVM_PIN}"
}

# Go toolchain -> /usr/local (root). Needed for lazydocker and other Go tools.
installGo() {
	echo "[!] Installing Go toolchain..."
	local GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
	curl -L -o /tmp/go.tar.gz "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
	sudo tar -C /usr/local -xzf /tmp/go.tar.gz
	rm /tmp/go.tar.gz
	export PATH="/usr/local/go/bin:$PATH"
}

# Rust/Cargo via rustup. User-space. Needed for tree-sitter, asm-lsp, alacritty, eza...
installRust() {
	echo "[!] Installing Rust/Cargo toolchain..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	source "$HOME/.cargo/env"
	rustup component add rust-analyzer
}

# cargo CLI tools: tree-sitter, asm-lsp, eza, bat, ripgrep, git-delta. User-space. Depends: rust.
installCargoTools() {
	echo "[!] Installing cargo tools..."
	source "$HOME/.cargo/env"
	cargo install --locked tree-sitter-cli
	cargo install --locked asm-lsp
	cargo install --locked eza
	cargo install --locked bat
	cargo install --locked ripgrep
	cargo install --locked git-delta
}

# Alacritty (own component: GUI-only, needs system -dev libs). User-space build. Depends: rust.
installAlacritty() {
	echo "[!] Building Alacritty..."
	source "$HOME/.cargo/env"
	cargo install --locked alacritty --features=x11,wayland
}

# Node.js -> /usr/local (root) + npm globals (~/.npm-global). Needed for CoC.
installNode() {
	echo "[!] Installing Node.js + npm globals..."
	sudo bash -c "curl -sL install-node.vercel.app/lts | bash"
	mkdir -p "$HOME/.npm-global"
	npm config set prefix "$HOME/.npm-global" --location=user
	export PATH="$HOME/.npm-global/bin:$PATH"
	npm i -g neovim yarn bash-language-server prettier
}

# VirtualBox (apt via Oracle repo). Root, full-mode.
installVirtualBox() {
	echo "[!] Installing VirtualBox..."
	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
	# VirtualBox repo uses bookworm for trixie (no trixie repo yet)
	local VB_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
	[[ "$VB_CODENAME" == "trixie" ]] && VB_CODENAME="bookworm"
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian ${VB_CODENAME} contrib" | \
		sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null
	sudo apt update
	local VB_PKG=$(apt-cache search virtualbox | grep -oP '^virtualbox-\d+\.\d+' | sort -V | tail -1)
	$INSTALL "$VB_PKG" || echo "[!] Warning: VirtualBox could not be installed (missing dependencies for this distro version). Skipping."
}

# Docker CE (apt via Docker repo). Root, full-mode.
installDocker() {
	echo "[!] Installing Docker..."
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg 2>/dev/null; done
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DISTRO} \
	$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt update
	$INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo usermod -a -G docker "$USER"
}

# Thin wrapper preserving the original FULL/MINIMAL order (behavior-preserving).
checkPackages() {
	local MODE="${1:-full}"
	cd "$HOME"
	echo "[!] Installing required packages..."
	installSyspkgsCore
	[[ "$MODE" == "full" ]] && installSyspkgsFull
	installPipxTools
	installGo
	installRust
	installCargoTools
	installAlacritty
	installNode
	if [[ "$MODE" == "full" ]]; then
		echo "[+] Installing FULL mode extras (VirtualBox, Docker)..."
		installVirtualBox
		installDocker
	fi
}

installShell() {
	echo "[!] Installing: zsh, oh my zsh, fzf, eza"
	read -n 1 -r -s -p $'Press enter to continue...\n'
	local zssh=$(command -v zsh)
	if [ -z "$zssh" ]; then
		$INSTALL zsh
	fi

	wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
	# --unattended: skip oh-my-zsh's own chsh prompt and its final `exec zsh -l`,
	# which would otherwise pause the install inside an interactive shell.
	sh install.sh --unattended
	rm install.sh

	# Set zsh as the login shell explicitly (root via sudo, so no password prompt).
	if [ "$SHELL" != "$(command -v zsh)" ]; then
		sudo chsh -s "$(command -v zsh)" "$USER"
	fi

	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	# Non-interactive: generate ~/.fzf.zsh with bindings+completion, but don't touch
	# rc files (repo .zshrc sources ~/.fzf.zsh itself and is copied over later anyway).
	~/.fzf/install --key-bindings --completion --no-update-rc
}

# Neovim binary -> /opt/neovim (root) + symlink to /usr/local/bin/nvim.
installNeovim() {
	echo "[!] Installing: neovim"
	pushd /tmp > /dev/null

	sudo mkdir -p /opt/neovim
	LOCATION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/neovim/neovim/releases/download/[^"]+/nvim-linux-x86_64\.tar\.gz"' |
		awk -F'"' '{ print $4 }')
	curl -L -o neovim.tar.gz "$LOCATION"
	tar -xf neovim.tar.gz
	sudo mv nvim-linux-x86_64/* /opt/neovim/
	rm -rf nvim-linux-x86_64
	rm neovim.tar.gz
	sudo ln -sf /opt/neovim/bin/nvim /usr/local/bin/nvim

	popd > /dev/null
}

# Ghidra -> /opt/ghidra (root).
installGhidra() {
	echo "[!] Installing: ghidra"
	pushd /tmp > /dev/null
	sudo mkdir -p /opt/ghidra
	LOCATION=$(curl -s https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/NationalSecurityAgency/ghidra/releases/download/[^"]+ghidra_[^"]+_PUBLIC_[^"]+\.zip"' |
		awk -F'"' '{ print $4 }')
	curl -L -o ghidra.zip "$LOCATION"
	unzip -q ghidra.zip
	folder=$(find . -maxdepth 1 -type d -name "ghidra_*" | head -n1)
	sudo mv "$folder"/* /opt/ghidra/
	rm -rf "$folder"
	rm ghidra.zip
	sudo ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra
	popd > /dev/null
}

# lazydocker via go install. Depends: go.
installLazydocker() {
	echo "[!] Installing: lazydocker"
	export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
	go install github.com/jesseduffield/lazydocker@latest
}

# GDB built from source (multi-arch + hex-escape patch) -> /opt/gdb. Depends: syspkgs-full.
installGdb() {
	echo "[!] Building GDB from source..."
	mkdir -p "$HOME/patches"
	cp -r "$REPO_DIR/patches/"* "$HOME/patches/"
	sudo mkdir -p /opt/gdb
	sudo chown "$USER:$USER" /opt/gdb
	pushd /opt/gdb > /dev/null
	# Pin to a fixed release tag so patches/gdb.patch always applies deterministically.
	# Master drifts constantly (the escape-printing code even moved valprint.c -> char-print.c),
	# which is why floating on master kept breaking the patch. To upgrade: bump GDB_TAG, then
	# regenerate patches/gdb.patch against the new tag.
	local GDB_TAG="gdb-16.3-release"
	git clone --depth 1 --branch "$GDB_TAG" https://sourceware.org/git/binutils-gdb.git .
	git apply --3way "$HOME/patches/gdb.patch"
	CFLAGS="-O2" ./configure --enable-targets=all \
		--with-system-readline \
		--with-python=/usr/bin/python3 \
		--enable-gdbserver \
		--disable-binutils --disable-ld --disable-gold \
		--disable-gas --disable-gprof --disable-sim
	make -j "$(nproc)"
	sudo make install
	popd > /dev/null
}

# GEF + GEP (GDB plugins). Depends: gdb.
installGefGep() {
	echo "[!] Installing GEF + GEP..."
	cd "$HOME"
	sudo cpan Unicode::GCString
	sudo cpan App::cpanminus
	sudo cpan YAML::Tiny
	sudo perl -MCPAN -e 'install "File::HomeDir"'
	# Fetch the latest GEF into a stable, version-less filename that ~/.gdbinit sources
	# (see dotfiles/.gdbinit). We avoid the blah.cat installer because it writes a
	# version-stamped filename (~/.gef-<tag>.py) and a matching source line into ~/.gdbinit
	# that importCFG later overwrites when it copies the repo's .gdbinit.
	local GEF_FILE="$HOME/.gef-gdb.py"
	curl -fsSL https://raw.githubusercontent.com/hugsy/gef/main/gef.py -o "$GEF_FILE"
	# Opcode spacing tweak: put a space between opcode bytes. Anchored on the code
	# expression (not a line number), so it keeps working across GEF version bumps.
	if grep -q '"".join(f"{b:02x}"' "$GEF_FILE"; then
		sed -i 's/"".join(f"{b:02x}"/" ".join(f"{b:02x}"/' "$GEF_FILE"
	else
		echo "[!] Warning: GEF opcode expression not found; spacing tweak not applied (upstream may have changed)"
	fi
	git clone --depth 1 https://github.com/lebr0nli/GEP.git "$HOME/.local/share/GEP"
	# --skip-gdbinit: the repo's .gdbinit already sources GEP (importCFG would clobber
	# any line GEP appends here anyway).
	"$HOME/.local/share/GEP/install.sh" --skip-gdbinit
}

# Thin wrapper preserving the original FULL install order (git-delta moved to cargo-tools).
installExtras() {
	installGhidra
	installLazydocker
	installGdb
	installGefGep
}

installPlugins() {
	echo "[!] Installing: vim-plug, powerlevel10k, zsh-autosuggestions"
	read -n 1 -r -s -p $'Press enter to continue...\n'
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
}

selectTheme() {
	echo ""
	echo "[!] Select your Neovim color scheme:"
	echo "    1) molokai-dark (default)"
	echo "    2) catppuccin"
	echo "    3) kanagawa"
	echo "    4) onedark"
	echo "    5) vscode"
	echo "    6) dracula"
	echo "    7) tokyodark"
	echo "    8) gruvbox"
	echo ""
	read -p "Enter your choice [1-8] (default: 1): " theme_choice

	case "$theme_choice" in
		2) selected_theme="catppuccin" ;;
		3) selected_theme="kanagawa" ;;
		4) selected_theme="onedark" ;;
		5) selected_theme="vscode" ;;
		6) selected_theme="dracula" ;;
		7) selected_theme="tokyodark" ;;
		8) selected_theme="gruvbox" ;;
		*) selected_theme="molokai-dark" ;;
	esac

	echo "$selected_theme" > "$HOME/.vim_theme"
	echo "[+] Theme set to: $selected_theme"
	echo "    You can change it later by editing ~/.vim_theme"
}

setupAlacritty() {
	echo "[!] Setting up Alacritty desktop integration..."

	mkdir -p "$HOME/.local/share/applications"
	cat > "$HOME/.local/share/applications/alacritty.desktop" << 'EOF'
[Desktop Entry]
Type=Application
TryExec=alacritty
Exec=alacritty
Icon=alacritty
Terminal=false
Categories=System;TerminalEmulator;
Name=Alacritty
GenericName=Terminal
Comment=A fast, cross-platform, OpenGL terminal emulator
StartupNotify=true
EOF

	# Set Ctrl+Alt+T shortcut based on desktop environment.
	# Ubuntu reports XDG_CURRENT_DESKTOP as "ubuntu:GNOME", so match substrings.
	local DE="${XDG_CURRENT_DESKTOP,,}"
	case "$DE" in
		*gnome*|*ubuntu*|*pop*)
			echo "[+] Configuring GNOME shortcut..."
			# Free Ctrl+Alt+T from GNOME's built-in terminal launcher, which
			# otherwise shadows the custom keybinding.
			gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]"

			local KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
			dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "['${KB_PATH}']"
			dconf write "${KB_PATH}name" "'Alacritty'"
			dconf write "${KB_PATH}command" "'alacritty'"
			dconf write "${KB_PATH}binding" "'<Ctrl><Alt>t'"
			;;
		*)
			echo "[*] DE '$XDG_CURRENT_DESKTOP' not configured — set Ctrl+Alt+T shortcut manually to: alacritty"
			;;
	esac
}

installFont() {
	echo "[!] Installing: 0xProto font from nerd-fonts"
	read -n 1 -r -s -p $'Press enter to continue...\n'
	LOCATION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/ryanoasis/nerd-fonts/releases/download/[^"]+0xProto\.zip"' |
		awk -F'"' '{ print $4 }')
	curl -L -o /tmp/0xProto.zip "$LOCATION"
	pushd /tmp > /dev/null
	unzip 0xProto.zip 0xProtoNerdFont-Regular.ttf 0xProtoNerdFont-Bold.ttf 0xProtoNerdFont-Italic.ttf
	mkdir -p ~/.local/share/fonts/
	mv 0xProtoNerdFont-Regular.ttf 0xProtoNerdFont-Bold.ttf 0xProtoNerdFont-Italic.ttf ~/.local/share/fonts/
	rm 0xProto.zip
	popd > /dev/null
	fc-cache -f
}

# Config deploy (TIER-1 FLOOR): copy all dotfiles. No tools required, no root.
installConfigDeploy() {
	local MODE="${1:-full}"
	echo "[!] Deploying configuration files"
	mkdir -p "$HOME/repos"

	# Neovim config + snippet symlinks
	mkdir -p "$HOME/.config"
	cp -r "$REPO_DIR/dotfiles/.config/nvim" "$HOME/.config/"
	ln -sf "$HOME/.config/nvim/custom-snippets/c.snippets" "$HOME/.config/nvim/custom-snippets/cpp.snippets"
	ln -sf "$HOME/.config/nvim/custom-snippets/asm.snippets" "$HOME/.config/nvim/custom-snippets/s.snippets"
	ln -sf "$HOME/.config/nvim/custom-snippets/asm.snippets" "$HOME/.config/nvim/custom-snippets/S.snippets"

	# Shell / git / editor / claude / alacritty dotfiles
	cd "$HOME"
	cp "$REPO_DIR/dotfiles/.zshenv" "$HOME/"
	cp "$REPO_DIR/dotfiles/.zshrc" "$HOME/"
	cp "$REPO_DIR/dotfiles/.p10k.zsh" "$HOME/"
	cp "$REPO_DIR/dotfiles/.gitconfig" "$HOME/"
	cp "$REPO_DIR/dotfiles/.clang-format" "$HOME/"
	cp -r "$REPO_DIR/dotfiles/.ssh" "$HOME/" 2>/dev/null || echo "SSH config skipped"
	mkdir -p "$HOME/.claude/agents/voltagent"
	cp "$REPO_DIR/dotfiles/.claude/statusline.sh" "$HOME/.claude/"
	cp "$REPO_DIR/dotfiles/.claude/settings.json" "$HOME/.claude/"
	cp "$REPO_DIR/dotfiles/.claude/programming.md" "$HOME/.claude/"
	cp "$REPO_DIR/dotfiles/.claude/agents/"*.md "$HOME/.claude/agents/"
	cp "$REPO_DIR/dotfiles/.claude/agents/voltagent/"*.md "$HOME/.claude/agents/voltagent/"
	cp -r "$REPO_DIR/dotfiles/.config/alacritty" "$HOME/.config/"
	cp "$REPO_DIR/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
	setupAlacritty

	if [[ "$MODE" == "full" ]]; then
		cp "$REPO_DIR/dotfiles/.gdbinit" "$HOME/"
		cp "$REPO_DIR/dotfiles/.gef.rc" "$HOME/"
		mkdir -p "$HOME/scripts"
		cp -r "$REPO_DIR/scripts/"* "$HOME/scripts/"
		chmod +x "$HOME/scripts/"*
	fi
}

# Neovim plugin setup (headless). Depends: neovim, node, plugins, config-deploy.
installNvimPlugins() {
	echo "[!] Setting up Neovim plugins (headless)..."
	/opt/neovim/bin/nvim --headless +PlugInstall +qa
	/opt/neovim/bin/nvim --headless +CocUpdate +qa
	/opt/neovim/bin/nvim --headless +"CocInstall -sync coc-snippets coc-json coc-vimtex coc-rust-analyzer coc-pyright coc-ltex coc-html coc-css coc-clangd coc-sh coc-markdownlint coc-prettier" +qa
	/opt/neovim/bin/nvim --headless +PlugUpdate +qa
	/opt/neovim/bin/nvim --headless +PlugUpgrade +qa
	/opt/neovim/bin/nvim --headless +"TSInstall c cpp python bash lua vim vimdoc markdown markdown_inline latex rust json yaml toml html css javascript make cmake" +qa
	/opt/neovim/bin/nvim --headless +"TSUpdate" +qa
}

# Network: firewall + static IP + services + docker compose (root, full). Depends: docker.
installNetwork() {
	# ============================================================================
	# NETWORK CONFIGURATION
	# ============================================================================
	echo ""
	echo "[+] Configuring network settings..."

	if [ ! -f "$REPO_DIR/network.conf" ]; then
		cp "$REPO_DIR/network.conf.example" "$REPO_DIR/network.conf"
		echo "[!] Created network.conf from template"
	fi

	read -n 1 -r -s -p $'[!] REQUIRED: Configure network settings in network.conf\n    - DNS_SERVER: Your DNS server IP (Pi-hole, router, or 8.8.8.8)\n    - HOST_IP: This machine\'s static IP address\n    - GATEWAY: Your router\'s IP address\n    - NETMASK: Network mask (default: 24 for 255.255.255.0)\n    - WAN_IFACE: Leave empty for auto-detection or specify interface name\nPress enter to open the file...\n'
	/opt/neovim/bin/nvim "$REPO_DIR/network.conf"

	source "$REPO_DIR/network.conf"

	if [ -z "$DNS_SERVER" ] || [ -z "$HOST_IP" ] || [ -z "$GATEWAY" ]; then
		echo "[!] ERROR: DNS_SERVER, HOST_IP, and GATEWAY are required in network.conf"
		exit 1
	fi

	if [ -z "$WAN_IFACE" ]; then
		WAN_IFACE=$(ip -o link show | awk -F': ' '$2 !~ /^(lo|vbox|docker|br-)/ {print $2; exit}')
		if [ -z "$WAN_IFACE" ]; then
			echo "[!] ERROR: Could not auto-detect network interface. Please specify WAN_IFACE in network.conf"
			exit 1
		fi
		echo "[+] Auto-detected network interface: $WAN_IFACE"
	fi

	NETMASK="${NETMASK:-24}"

	echo "[+] Applying network configuration..."
	echo "    DNS_SERVER: $DNS_SERVER"
	echo "    HOST_IP: $HOST_IP"
	echo "    GATEWAY: $GATEWAY"
	echo "    NETMASK: $NETMASK"
	echo "    WAN_IFACE: $WAN_IFACE"

	sudo cp "$REPO_DIR/network.conf" /etc/network.conf
	sudo chmod 600 /etc/network.conf
	sudo chown root:root /etc/network.conf

	# Copy network and firewall scripts to /etc (they source config at runtime)
	sudo cp "$REPO_DIR/dotfiles/network-static.sh" /etc/network-static.sh
	sudo cp "$REPO_DIR/dotfiles/firewall.sh" /etc/firewall.sh
	sudo chmod 700 /etc/network-static.sh
	sudo chmod 700 /etc/firewall.sh
	sudo chown root:root /etc/network-static.sh
	sudo chown root:root /etc/firewall.sh

	sudo cp "$REPO_DIR/dotfiles/network-static.service" /etc/systemd/system/
	sudo cp "$REPO_DIR/dotfiles/firewall.service" /etc/systemd/system/
	sudo chmod 644 /etc/systemd/system/network-static.service
	sudo chmod 644 /etc/systemd/system/firewall.service
	sudo chown root:root /etc/systemd/system/network-static.service
	sudo chown root:root /etc/systemd/system/firewall.service

	# Process Docker configurations (copy as-is, configs loaded via env vars at runtime)
	mkdir -p "$HOME/dockers"
	for docker_dir in "$REPO_DIR/dockers/"*/; do
		docker_name=$(basename "$docker_dir")
		mkdir -p "$HOME/dockers/$docker_name"
		cp -r "$docker_dir"* "$HOME/dockers/$docker_name/"
	done

	echo "[+] Network configuration applied successfully"

	# Start Docker containers with network config environment variables
	source "$REPO_DIR/network.conf"
	export DNS_SERVER HOST_IP GATEWAY NETMASK WAN_IFACE
	for i in $(/bin/ls "$HOME/dockers" 2>/dev/null); do
		docker compose -f "$HOME/dockers/$i/docker-compose.yaml" up -d 2>/dev/null || \
		docker compose -f "$HOME/dockers/$i/docker-compose.yml" up -d 2>/dev/null || true
	done



	read -r -p "[?] Disable ipv6 (y/n): " user_input
	if [[ "$user_input" == "y" ]]; then
		sudo /opt/neovim/bin/nvim /etc/default/grub
		sudo update-grub
	fi

	echo ""
	read -n 1 -r -s -p $'[!] REQUIRED: Enable IPv4 forwarding in /etc/sysctl.conf\n    Add or uncomment: net.ipv4.ip_forward=1\nPress enter to open the file...\n'
	sudo /opt/neovim/bin/nvim /etc/sysctl.conf

	# Configure ulogd2 for firewall logging
	sudo mkdir -p /var/log/ulog
	sudo cp "$REPO_DIR/dotfiles/ulogd.conf" /etc/ulogd.conf
	sudo chown root:root /etc/ulogd.conf
	sudo chmod 644 /etc/ulogd.conf

	# Enable services (network-static must start before firewall)
	sudo systemctl daemon-reload
	sudo systemctl enable network-static.service
	sudo systemctl enable firewall.service
	sudo systemctl enable ulogd2.service
	sudo systemctl start network-static.service
	sudo systemctl start firewall.service
	sudo systemctl start ulogd2.service

	echo "[*] NOTE: If dual-booting with Windows, run: sudo timedatectl set-local-rtc 1"

	# Cleanup unwanted packages
	sudo apt remove -y cups-client cups-common ufw imagemagick 'libreoffice*' gdb gdb-multiarch 2>/dev/null
	sudo apt autoremove -y

}

# Thin wrapper preserving the original FULL/MINIMAL flow.
importCFG() {
	local MODE="${1:-full}"
	echo "[!] Importing configuration"
	installConfigDeploy "$MODE"
	installNvimPlugins
	if [[ "$MODE" != "full" ]]; then
		echo "[+] MINIMAL installation complete!"
		echo ""
		echo "Next steps:"
		echo "  1. Restart your shell or run: source ~/.zshrc"
		echo "  2. Open Neovim and themes will be loaded automatically"
		echo "  3. Change theme anytime by editing ~/.vim_theme"
		return
	fi
	installNetwork
}

echo "[!] Installation script by Josep Comes. This script is intended to work with apt"
echo ""
echo "[?] Select installation mode:"
echo "    1) FULL - Complete development environment (recommended for personal systems)"
echo "       Includes: Full shell setup, Neovim, GDB, Ghidra, Docker, firewall, VMs, all tools"
echo ""
echo "    2) MINIMAL - Essential dotfiles only (for corporate/restricted environments)"
echo "       Includes: Full shell setup, Neovim, Font, basic tools"
echo "       Skips: GDB build, Docker, firewall, TeX Live, Ghidra, system services"
echo ""
read -p "Enter your choice [1-2] (default: 1): " install_mode

case "$install_mode" in
	2)
		INSTALL_MODE="minimal"
		echo "[+] MINIMAL installation selected"
		;;
	*)
		INSTALL_MODE="full"
		echo "[+] FULL installation selected"
		;;
esac

echo ""
if [[ "$INSTALL_MODE" == "full" ]]; then
	echo "[!] The following tools will be installed:"
	echo "[+] Terminal: alacritty, tmux, tmuxinator"
	echo "[+] Shell: zsh, oh my zsh, fzf, eza"
	echo "[+] Editor: neovim"
	echo "[+] Tools: batcat, ripgrep, git-delta, lazydocker"
	echo "[+] Extras: ghidra"
	echo "[+] Font: 0xProto"
	echo "[+] Plugins: powerlevel10k, zsh-autosuggestions, vim-plug, coc"
	echo "[+] Themes: molokai-dark, catppuccin, kanagawa, onedark, vscode, dracula, tokyodark, gruvbox"
	echo "[+] Build tools: Go, Rust/Cargo, TeX Live, GDB from source"
	echo "[+] System: Firewall, network services, Docker, VirtualBox"
else
	echo "[!] The following tools will be installed:"
	echo "[+] Terminal: alacritty, tmux, tmuxinator"
	echo "[+] Shell: zsh, oh my zsh, fzf, eza"
	echo "[+] Editor: neovim"
	echo "[+] Tools: batcat, ripgrep"
	echo "[+] Font: 0xProto"
	echo "[+] Plugins: powerlevel10k, zsh-autosuggestions, vim-plug, coc"
	echo "[+] Themes: molokai-dark, catppuccin, kanagawa, onedark, vscode, dracula, tokyodark, gruvbox"
	echo "[+] Build tools: Go, Rust/Cargo, Node.js"
fi
read -n 1 -r -s -p $'Press enter to continue...\n'

if [[ "$INSTALL_MODE" == "full" ]]; then
	removeSnap
else
	echo ""
	read -r -p "[?] Remove snap from system? (y/N): " snap_choice
	if [[ "$snap_choice" =~ ^[Yy]$ ]]; then
		removeSnap
	fi
fi

checkPackages "$INSTALL_MODE"
installShell
installNeovim
if [[ "$INSTALL_MODE" == "full" ]]; then
	installExtras
fi
installFont
installPlugins
selectTheme
importCFG "$INSTALL_MODE"
