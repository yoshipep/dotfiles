# Development Environment Setup Repository

Automated development environment setup for **Ubuntu** systems with two installation modes.

## Installation Modes

### FULL Mode (Default)

Complete development environment for personal systems:

- **Shell**: zsh, oh-my-zsh, powerlevel10k
- **Terminal**: terminator
- **Editor**: Neovim with all plugins and 7 themes
- **Development**: GDB (custom build), Ghidra, Docker, VirtualBox, meld
- **Network**: Custom firewall with VM isolation, static IP, system services
- **Tools**: batcat, ripgrep, git-delta, lazydocker, tree-sitter and many more
- **Python**: virtualenvwrapper, autopep8, isort
- **Build**: Rust/Cargo, Node.js, TeX Live, OpenJDK, bash-language-server

### MINIMAL Mode

Essential dotfiles for corporate/restricted environments:

- **Shell**: zsh, oh-my-zsh, powerlevel10k, fzf, eza
- **Terminal**: terminator
- **Editor**: Neovim with all plugins and 7 themes
- **Tools**: batcat, ripgrep, tree-sitter, clangd, clang-format, shellcheck
- **Build**: Rust/Cargo (for tree-sitter), Node.js (for CoC)

**Skips**: GDB build, Docker, Ghidra, VirtualBox, firewall, TeX Live, system services, git-delta, lazydocker, KeePassXC, meld, ipython3, virtualenvwrapper

## Usage

```bash
bash install_env.sh
```

The installer will prompt for:

1. **Installation mode** (FULL or MINIMAL)
2. **Neovim theme** (molokai-dark, catppuccin, kanagawa, onedark, vscode, dracula, tokyodark, gruvbox)
3. **Network configuration** (FULL mode only - DNS, IP, gateway)

## Configuration During Installation

### Neovim Theme Selection (Both Modes)

Choose from 7 colorschemes during installation. Theme is saved to `~/.vim_theme` and can be changed later.

### Network Configuration (FULL Mode Only)

During installation, the installer will **prompt you to open and edit `network.conf`** with your settings:

- `DNS_SERVER`: Your DNS server IP (Pi-hole, router, or 8.8.8.8)
- `HOST_IP`: This machine's static IP address
- `GATEWAY`: Your router's IP address
- `NETMASK`: Network mask (default: 24)
- `WAN_IFACE`: Leave empty for auto-detection

Configuration is copied to `/etc/network.conf` and loaded **at runtime** (no hardcoded values). All scripts source this file dynamically.

**After installation - Changing Networks:**

```bash
net config
# Opens /etc/network.conf in editor
# Edit values, save, and exit
# Prompts: Apply changes now? (Docker + Firewall) [Y/n]
# Press Enter → Everything reloads automatically
```

**Manual configuration required:**

- **IPv4 forwarding**: Enable in `/etc/sysctl.conf` (prompted during installation)
- **IPv6**: Option to disable

## Key Features

### Firewall Control (FULL Mode)

**Network Access Control:**

- `net on` - Enable host network access (internet browsing)
- `net off` - Disable host network access
- `net don` - Enable Docker container network access
- `net doff` - Disable Docker container network access
- `net status` - Show current host and Docker network status

**Firewall Management:**

- `net config` - Edit `/etc/network.conf` and optionally apply changes (reload Docker + Firewall)
- `net start` - Reload firewall rules from `/etc/network.conf` (useful if you edit config manually)
- `net enable` - Enable firewall (set default DROP policy)
- `net disable` - Disable firewall (set default ACCEPT policy - allows all traffic)
- `net flush` - Flush all iptables rules (emergency use)

### Docker Integration (FULL Mode)

Containers requiring internet must use:

```yaml
network_mode: bridge
dns:
    - ${DNS_SERVER} # Loaded from /etc/network.conf at runtime
```

This routes traffic through the firewall's FORWARD chain, enabling `net don/doff` control. DNS is loaded dynamically from `/etc/network.conf` via environment variables.

### SSH Configuration for VMs (FULL Mode)

SSH keys must be generated manually:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/vbox_vm_name -C "vm-name"
ssh-copy-id -i ~/.ssh/vbox_vm_name.pub user@vm_ip
```

⚠️ **Security note**: Private keys are NOT included in this repository.

## Repository Structure

```
.
├── install_env.sh          # Main installation script with mode selection
├── network.conf.example    # Network configuration template
├── dotfiles/               # User configurations
│   ├── .zshrc, .p10k.zsh  # Shell configuration
│   ├── .clang-format      # C/C++ code formatting
│   ├── .gef.rc            # GDB Enhanced Features
│   ├── .gdbinit           # GDB configuration
│   ├── firewall.sh        # Firewall script (installed to /etc/)
│   ├── network-static.sh  # Static IP script (installed to /etc/)
│   ├── firewall.service   # Systemd service (installed to /etc/systemd/system/)
│   ├── network-static.service # Systemd service (installed to /etc/systemd/system/)
│   └── .config/           # Application configurations
│       ├── nvim/          # Neovim with plugins and themes
│       ├── terminator/    # Terminator terminal
│       └── coc/           # Conquer of Completion
├── scripts/               # Utility scripts (net, opensocat, seek, sz)
├── patches/               # Patches (gdb.patch, gef.patch)
└── dockers/               # Docker Compose configurations
```

## Installed System Structure (FULL Mode)

```
/etc/
├── network.conf                    # Network configuration (600, root:root)
├── firewall.sh                     # Firewall script (700, root:root)
├── network-static.sh               # Static IP script (700, root:root)
└── systemd/system/
    ├── firewall.service            # Firewall systemd service (644, root:root)
    └── network-static.service      # Network systemd service (644, root:root)

$HOME/
├── scripts/                        # Utility scripts
│   └── net                         # Firewall control wrapper
└── dockers/                        # Docker Compose files (use ${DNS_SERVER})
```

## Notes

- **Dynamic Configuration**: All network settings loaded at runtime from `/etc/network.conf`
- **Changing Networks**: Use `net config` to edit configuration and reload Docker + Firewall
- **Configuration Security**: `network.conf` is gitignored to prevent committing network details
- **SSH Keys**: User-specific, NOT included in repository
- **System Services** (FULL mode): Firewall and static network services auto-enabled
- **Docker Control** (FULL mode): Use `net don/doff` for container internet access
- **GDB** (FULL mode): Built from source with multi-arch support and custom patch
- **Snap Removal**: Optional during installation with apt pinning
- **Font**: Terminator requires manual configuration to use Agave Nerd Font
