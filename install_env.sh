#!/bin/bash

INSTALL="sudo apt install -y"

removeSnap() {
	echo "[!] Do you want to remove snap from the system?"
	echo "    This will remove all snap packages, snapd, and prevent reinstallation."
	read -p "    Remove snap? (y/N): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "[*] Skipping snap removal."
		return
	fi

	echo "[!] Starting snap removal process..."

	# List installed snaps
	echo "[1/6] Checking installed snaps..."
	snap list 2>/dev/null || true
	echo

	# Remove all snap packages
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

	# Stop and disable snapd services
	echo "[3/6] Stopping and disabling snapd services..."
	sudo systemctl stop snapd.service 2>/dev/null || true
	sudo systemctl stop snapd.socket 2>/dev/null || true
	sudo systemctl stop snapd.seeded.service 2>/dev/null || true
	sudo systemctl disable snapd.service 2>/dev/null || true
	sudo systemctl disable snapd.socket 2>/dev/null || true
	sudo systemctl disable snapd.seeded.service 2>/dev/null || true
	echo

	# Remove snapd packages
	echo "[4/6] Removing snapd packages..."
	sudo apt-get purge -y snapd gnome-software-plugin-snap 2>/dev/null || true
	sudo apt-get autoremove -y || true
	echo

	# Clean up snap directories
	echo "[5/6] Cleaning up snap directories..."
	sudo rm -rf /snap
	sudo rm -rf /var/snap
	sudo rm -rf /var/lib/snapd
	sudo rm -rf /var/cache/snapd
	sudo rm -rf /usr/lib/snapd
	rm -rf ~/snap
	echo "  [*] Directories removed"
	echo

	# Prevent snap from being reinstalled
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

checkPackages() {
	cd "$HOME"
	echo "[!] Installing required packages..."
	$INSTALL software-properties-common
	sudo add-apt-repository -y ppa:git-core/ppa
	sudo add-apt-repository -y ppa:phoerious/keepassxc
	sudo apt update
	sudo apt upgrade -y
	$INSTALL build-essential
	$INSTALL keepassxc
	$INSTALL git
	$INSTALL perl
	$INSTALL gawk
	$INSTALL curl
	$INSTALL wget
	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
	$INSTALL pip
	$INSTALL meld
	$INSTALL "python$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')-venv"
	$INSTALL python3-autopep8
	$INSTALL python3-virtualenvwrapper
	$INSTALL python3-pynvim
	$INSTALL python3-isort
	$INSTALL isort
	$INSTALL ipython3
	$INSTALL terminator
	$INSTALL htop
	$INSTALL clangd
	$INSTALL clang-format
	$INSTALL xclip
	$INSTALL libmpfr-dev
	$INSTALL libgmp-dev
	$INSTALL libmpc-dev
	$INSTALL flex
	$INSTALL bison
	$INSTALL autoconf
	$INSTALL automake
	$INSTALL pkg-config
	$INSTALL shellcheck
	$INSTALL socat
	# GDB build dependencies (for multi-arch support)
	$INSTALL libreadline-dev
	$INSTALL libncurses-dev
	$INSTALL python3-dev
	$INSTALL libexpat-dev
	$INSTALL zlib1g-dev
	$INSTALL libbabeltrace-dev
	$INSTALL libipt-dev
	local openjdk=$(apt-cache search openjdk | awk '{print $1}' | grep -oP '^openjdk-\d{1,2}-jdk$' | sort -V | tail -n 1)
	$INSTALL "$openjdk"
	# Install Rust and Cargo for building from source
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	source "$HOME/.cargo/env"
	sudo bash -c "curl -sL install-node.vercel.app/lts | bash"
	mkdir -p "$HOME/.npm-global"
	npm config set prefix "$HOME/.npm-global" --location=user
	export PATH="$HOME/.npm-global/bin:$PATH"
	npm i -g neovim
	npm i -g yarn
	npm i -g bash-language-server
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
	sudo apt update
	$INSTALL ca-certificates
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt update
	$INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo usermod -a -G docker "$USER"
	$INSTALL ulogd2
	sudo apt remove -y cups-client
	sudo apt remove -y cups-common
	sudo apt remove -y ufw
	sudo apt autoremove -y
}

installShell() {
	echo "[!] Installing: zsh, oh my zsh, fzf, eza"
	read -n 1 -r -s -p $'Press enter to continue...\n'
	local zssh=$(which zsh)
	if [ -z "$zssh" ]; then
		$INSTALL zsh
	fi

	wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
	sh install.sh
	rm install.sh

	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install

	cd /tmp
	LOCATION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/eza-community/eza/releases/download/[^"]+eza_x86_64-unknown-linux-gnu\.tar\.gz"' |
		awk -F'"' '{ print $4 }')
	curl -L -o eza.tar.gz "$LOCATION"
	tar -xzf eza.tar.gz
	sudo mv ./eza /usr/local/bin/

	# Install completions if available
	COMP_URL=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/eza-community/eza/releases/download/[^"]+completions-[^"]+\.tar\.gz"' |
		awk -F'"' '{ print $4 }')
	if [ -n "$COMP_URL" ]; then
		curl -L -o completions.tar.gz "$COMP_URL"
		tar -xzf completions.tar.gz
		sudo mkdir -p /usr/local/share/zsh/site-functions
		sudo mv ./target/completions-*/eza /usr/local/share/zsh/site-functions/_eza 2>/dev/null || true
	fi
}

installExtras() {
	echo "[!] Installing: ghidra, neovim, batcat, ripgrep, git-delta, lazydocker"
	read -n 1 -r -s -p $'Press enter to continue...\n'
	cd /tmp

	# Install Ghidra to /opt
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

	# Install Neovim to /opt
	cd /tmp
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

	# Install batcat (keep as .deb)
	cd /tmp
	LOCATION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/sharkdp/bat/releases/download/[^"]+bat_[^"]+_amd64\.deb"' |
		awk -F'"' '{ print $4 }')
	curl -L -o batcat.deb "$LOCATION"
	sudo dpkg -i batcat.deb
	rm batcat.deb

	# Install ripgrep (keep as .deb)
	cd /tmp
	LOCATION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/BurntSushi/ripgrep/releases/download/[^"]+ripgrep_[^"]+_amd64\.deb"' |
		awk -F'"' '{ print $4 }')
	curl -L -o ripgrep.deb "$LOCATION"
	sudo dpkg -i ripgrep.deb
	rm ripgrep.deb

	# Install git-delta binary
	cd /tmp
	LOCATION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/dandavison/delta/releases/download/[^"]+delta-[^"]+-x86_64-unknown-linux-gnu\.tar\.gz"' |
		awk -F'"' '{ print $4 }')
	curl -L -o delta.tar.gz "$LOCATION"
	tar -xzf delta.tar.gz
	sudo mv delta-*/delta /usr/local/bin/
	rm -rf delta-*
	rm delta.tar.gz

	# Install lazydocker
	cd /tmp
	LOCATION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/jesseduffield/lazydocker/releases/download/[^"]+lazydocker_[^"]+_Linux_x86_64\.tar\.gz"' |
		awk -F'"' '{ print $4 }')
	curl -L -o lazydocker.tar.gz "$LOCATION"
	tar -xzf lazydocker.tar.gz lazydocker
	sudo mv lazydocker /usr/local/bin/
	rm lazydocker.tar.gz
}

installPlugins() {
	echo "[!] Installing: powerlevel10k, zsh-autosuggestions, vim-plug, coc"
	read -n 1 -r -s -p $'Press enter to continue...\n'
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
}

installFont() {
	echo "Installing: Agave font from nerd-fonts"
	read -n 1 -r -s -p $'Press enter to continue...\n'
	LOCATION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest |
		grep -Eo '"browser_download_url":\s*"https://github.com/ryanoasis/nerd-fonts/releases/download/[^"]+Agave\.zip"' |
		awk -F'"' '{ print $4 }')
	curl -L -o Agave.zip "$LOCATION"
	mv ./Agave.zip /tmp

	cd /tmp
	unzip Agave.zip
	mkdir ~/.local/share/fonts/ 2>/dev/null
	mv ./AgaveNerdFont-Regular.ttf ~/.local/share/fonts/
	fc-cache -f
}

importCFG() {
	echo "Importing configuration"
	REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

	cd "$HOME"
	mkdir -p projects
	mkdir -p repos
	mkdir -p patches

	# Copy patches first (needed for GDB build)
	cp -r "$REPO_DIR/patches/"* "$HOME/patches/"

	# Install TeX Live (provides texinfo needed for GDB build)
	mkdir -p /tmp/tex
	cp "$REPO_DIR/dotfiles/texlive.profile" /tmp/tex/
	cd /tmp
	wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
	tar -xf install-tl-unx.tar.gz -C ./tex --strip-components=1
	cd tex
	sudo perl ./install-tl -profile texlive.profile

	# Build GDB from source with patches and multi-arch support directly in /opt
	sudo mkdir -p /opt/gdb
	sudo chown "$USER:$USER" /opt/gdb
	cd /opt/gdb
	git clone https://sourceware.org/git/binutils-gdb.git .
	git apply "$HOME/patches/gdb.patch"
	./configure --enable-targets=all
	make -j "$(nproc)"
	sudo make install

	# Install universal-ctags from apt
	$INSTALL universal-ctags

	# Install dotfiles
	cd "$HOME"
	cp "$REPO_DIR/dotfiles/.zshrc" "$HOME/"
	cp "$REPO_DIR/dotfiles/.p10k.zsh" "$HOME/"
	cp "$REPO_DIR/dotfiles/.gitconfig" "$HOME/"
	cp "$REPO_DIR/dotfiles/.gef.rc" "$HOME/"
	cp "$REPO_DIR/dotfiles/.gdbinit" "$HOME/"
	cp "$REPO_DIR/dotfiles/.clang-format" "$HOME/"
	cp -r "$REPO_DIR/dotfiles/.ssh" "$HOME/" 2>/dev/null || echo "SSH config skipped"

	# Install config directories
	mkdir -p "$HOME/.config"
	cp -r "$REPO_DIR/dotfiles/.config/nvim" "$HOME/.config/"
	cp -r "$REPO_DIR/dotfiles/.config/terminator" "$HOME/.config/"

	# Create snippet symlinks
	ln -sf "$HOME/.config/nvim/custom-snippets/c.snippets" "$HOME/.config/nvim/custom-snippets/cpp.snippets"
	ln -sf "$HOME/.config/nvim/custom-snippets/asm.snippets" "$HOME/.config/nvim/custom-snippets/s.snippets"
	ln -sf "$HOME/.config/nvim/custom-snippets/S.snippets" "$HOME/.config/nvim/custom-snippets/s.snippets"

	# Install scripts
	mkdir -p "$HOME/scripts"
	cp -r "$REPO_DIR/scripts/"* "$HOME/scripts/"
	chmod +x "$HOME/scripts/"*

	# ============================================================================
	# NETWORK CONFIGURATION
	# ============================================================================
	echo ""
	echo "[+] Configuring network settings..."

	# Check if network.conf exists, if not create from example
	if [ ! -f "$REPO_DIR/network.conf" ]; then
		cp "$REPO_DIR/network.conf.example" "$REPO_DIR/network.conf"
		echo "[!] Created network.conf from template"
	fi

	# Prompt user to configure network.conf
	read -n 1 -r -s -p $'[!] REQUIRED: Configure network settings in network.conf\n    - DNS_SERVER: Your DNS server IP (Pi-hole, router, or 8.8.8.8)\n    - HOST_IP: This machine\'s static IP address\n    - GATEWAY: Your router\'s IP address\n    - NETMASK: Network mask (default: 24 for 255.255.255.0)\n    - WAN_IFACE: Leave empty for auto-detection or specify interface name\nPress enter to open the file...\n'
	vim "$REPO_DIR/network.conf"

	# Source network.conf to load values
	source "$REPO_DIR/network.conf"

	# Validate required values
	if [ -z "$DNS_SERVER" ] || [ -z "$HOST_IP" ] || [ -z "$GATEWAY" ]; then
		echo "[!] ERROR: DNS_SERVER, HOST_IP, and GATEWAY are required in network.conf"
		exit 1
	fi

	# Auto-detect WAN_IFACE if not specified
	if [ -z "$WAN_IFACE" ]; then
		WAN_IFACE=$(ip -o link show | awk -F': ' '$2 !~ /^(lo|vbox|docker|br-)/ {print $2; exit}')
		if [ -z "$WAN_IFACE" ]; then
			echo "[!] ERROR: Could not auto-detect network interface. Please specify WAN_IFACE in network.conf"
			exit 1
		fi
		echo "[+] Auto-detected network interface: $WAN_IFACE"
	fi

	# Set default NETMASK if not specified
	NETMASK="${NETMASK:-24}"

	# Function to substitute placeholders in a file
	substitute_config() {
		local src_file="$1"
		local dst_file="$2"

		sed -e "s|__DNS_SERVER__|${DNS_SERVER}|g" \
		    -e "s|__HOST_IP__|${HOST_IP}|g" \
		    -e "s|__GATEWAY__|${GATEWAY}|g" \
		    -e "s|__NETMASK__|${NETMASK}|g" \
		    -e "s|__WAN_IFACE__|${WAN_IFACE}|g" \
		    "$src_file" > "$dst_file"
	}

	echo "[+] Applying network configuration..."
	echo "    DNS_SERVER: $DNS_SERVER"
	echo "    HOST_IP: $HOST_IP"
	echo "    GATEWAY: $GATEWAY"
	echo "    NETMASK: $NETMASK"
	echo "    WAN_IFACE: $WAN_IFACE"

	# Process network and firewall configuration files
	substitute_config "$REPO_DIR/dotfiles/network-static.sh" "$HOME/network-static.sh"
	substitute_config "$REPO_DIR/dotfiles/firewall.sh" "$HOME/firewall.sh"
	cp "$REPO_DIR/dotfiles/network-static.service" "$HOME/"
	cp "$REPO_DIR/dotfiles/firewall.service" "$HOME/"

	# Process Docker configurations
	mkdir -p "$HOME/dockers"
	for docker_dir in "$REPO_DIR/dockers/"*/; do
		docker_name=$(basename "$docker_dir")
		mkdir -p "$HOME/dockers/$docker_name"

		# Copy all files from docker directory
		for file in "$docker_dir"*; do
			filename=$(basename "$file")
			if [[ "$filename" == "docker-compose.yml" ]] || [[ "$filename" == "docker-compose.yaml" ]]; then
				# Substitute placeholders in docker-compose files
				substitute_config "$file" "$HOME/dockers/$docker_name/$filename"
			else
				# Copy other files as-is
				cp "$file" "$HOME/dockers/$docker_name/"
			fi
		done
	done

	echo "[+] Network configuration applied successfully"

	# Start Docker containers
	for i in $(/bin/ls "$HOME/dockers" 2>/dev/null); do
		docker compose -f "$HOME/dockers/$i/docker-compose.yaml" up -d 2>/dev/null || \
		docker compose -f "$HOME/dockers/$i/docker-compose.yml" up -d 2>/dev/null || true
	done

	# Setup Neovim plugins
	/opt/neovim/bin/nvim --headless +PlugInstall +qa
	/opt/neovim/bin/nvim --headless +CocUpdate +qa
	/opt/neovim/bin/nvim --headless +PlugUpdate +qa
	/opt/neovim/bin/nvim --headless +PlugUpgrade +qa

	# Install Perl modules
	cd "$HOME"
	sudo cpan Unicode::GCString
	sudo cpan App::cpanminus
	sudo cpan YAML::Tiny
	sudo perl -MCPAN -e 'install "File::HomeDir"'

	# Install GEF
	bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

	# Apply GEF patch
	GEF_FILE=$(find "$HOME" -maxdepth 1 -name ".gef-*.py" | head -n 1)
	if [ -n "$GEF_FILE" ]; then
		cd "$HOME"
		patch -p0 < "$HOME/patches/gef.patch" || echo "[!] Warning: GEF patch may need updating for current version"
	else
		echo "[!] Warning: GEF file not found, patch not applied"
	fi

	# Optional IPv6 disable
	read -r -p "[?] Disable ipv6 (y/n): " user_input
	if [[ "$user_input" == "y" ]]; then
		sudo vim /etc/default/grub
		sudo update-grub
	fi

	# Configure IPv4 forwarding
	echo ""
	read -n 1 -r -s -p $'[!] REQUIRED: Enable IPv4 forwarding in /etc/sysctl.conf\n    Add or uncomment: net.ipv4.ip_forward=1\nPress enter to open the file...\n'
	sudo vim /etc/sysctl.conf

	# Install network and firewall configuration (already processed with network.conf values)
	chmod 770 "$HOME/network-static.sh"
	chmod 770 "$HOME/firewall.sh"
	sudo chown root:root "$HOME/network-static.sh"
	sudo chown root:root "$HOME/network-static.service"
	sudo chown root:root "$HOME/firewall.sh"
	sudo chown root:root "$HOME/firewall.service"
	sudo mv "$HOME/network-static.sh" /etc/
	sudo mv "$HOME/network-static.service" /etc/systemd/system/
	sudo mv "$HOME/firewall.sh" /etc/
	sudo mv "$HOME/firewall.service" /etc/systemd/system/

	echo "[+] Network and firewall configuration installed to /etc/"

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

	# Set RTC to local time (for dual-boot)
	timedatectl set-local-rtc 1
}

echo "[!] Installation script by Josep Comes. This script is intended to work with apt"
echo "[!] The following tools are going to be installed:"
echo "[+] Terminal: terminator"
echo "[+] Shell: zsh, oh my zsh, fzf, eza"
echo "[+] Extras: ghidra, neovim, batcat, ripgrep, git-delta, lazydocker"
echo "[+] Font: Agave"
echo "[+] Plugins: powerlevel10k, zsh-autosuggestions, vim-plug, coc"
echo "[+] Build tools: Rust/Cargo"
read -n 1 -r -s -p $'Press enter to continue...\n'

removeSnap
checkPackages
installShell
installExtras
installFont
installPlugins
importCFG
