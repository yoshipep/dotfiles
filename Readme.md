# Development Environment Setup Repository

Automated development environment setup for **Ubuntu** systems with two installation modes.

## Installation Modes

### FULL Mode (Default)

Complete development environment for personal systems:

- Shell: zsh, oh-my-zsh, eza, powerlevel10k
- Editor: Neovim with all plugins and 7 themes
- Development: GDB (custom build), Ghidra, Docker, VirtualBox
- Network: Custom firewall with VM isolation, static IP
- Tools: batcat, ripgrep, git-delta, lazydocker, tree-sitter, eza, fzf

### MINIMAL Mode

Essential dotfiles for corporate/restricted environments:

- Shell: zsh, oh-my-zsh, powerlevel10k
- Editor: Neovim with all plugins and 7 themes
- Terminal: terminator
- Tools: batcat, ripgrep, git-delta, lazydocker, tree-sitter, eza, fzf

**Skips**: GDB build, Docker, Ghidra, firewall, TeX Live, system services

## Usage

```bash
bash install_env.sh
```

The installer will prompt for:

1. **Installation mode** (FULL or MINIMAL)
2. **Neovim theme** (molokai-dark, catppuccin, kanagawa, onedark, vscode, dracula, tokyodark)
3. **Network configuration** (FULL mode only - edit `network.conf`)

## Configuration During Installation

### Neovim Theme Selection (Both Modes)

Choose from 7 colorschemes during installation. Theme is saved to `~/.vim_theme` and can be changed later.

### Network Configuration (FULL Mode Only)

Edit `network.conf` with your settings:

- `DNS_SERVER`: Your DNS server IP (Pi-hole, router, or 8.8.8.8)
- `HOST_IP`: This machine's static IP address
- `GATEWAY`: Your router's IP address
- `NETMASK`: Network mask (default: 24)
- `WAN_IFACE`: Leave empty for auto-detection

The installer automatically substitutes these values into firewall.sh, network-static.sh, and Docker configs.

**Manual configuration required:**

- **IPv4 forwarding**: Enable in `/etc/sysctl.conf` (prompted during installation)
- **IPv6**: Option to disable

## Key Features

### Firewall Control (FULL Mode)

- `net on/off`: Host internet access
- `net don/doff`: Docker container internet access
- `net status`: Show current status

### Docker Integration (FULL Mode)

Containers requiring internet must use:

```yaml
network_mode: bridge
dns:
    - __DNS_SERVER__
```

This routes traffic through the firewall's FORWARD chain, enabling `net don/doff` control.

### SSH Configuration for VMs (FULL Mode)

SSH keys must be generated manually:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/vbox_vm_name -C "vm-name"
ssh-copy-id -i ~/.ssh/vbox_vm_name.pub user@vm_ip
```

⚠️ **Security note**: Private keys are NOT included in this repository.

## Structure

```
.
├── install_env.sh          # Main installation script with mode selection
├── network.conf.example    # Network configuration template
├── dotfiles/               # User configurations
│   ├── .zshrc, .p10k.zsh  # Shell configuration
│   ├── .clang-format      # C/C++ code formatting
│   ├── .gef.rc            # GDB Enhanced Features
│   ├── .gdbinit           # GDB configuration
│   ├── firewall.sh        # Firewall script (auto-configured)
│   ├── network-static.sh  # Static IP script (auto-configured)
│   └── .config/           # Application configurations
│       ├── nvim/          # Neovim with plugins and themes
│       ├── terminator/    # Terminator terminal
│       └── coc/           # Conquer of Completion
├── scripts/               # Utility scripts (net, opensocat, seek, sz)
├── patches/               # Patches (gdb.patch, gef.patch)
└── dockers/               # Docker Compose configurations
```

## Notes

- **Configuration**: `network.conf` is gitignored to prevent committing network details
- **SSH keys**: User-specific, NOT included in repository
- **System services** (FULL mode): Firewall and static network services auto-enabled
- **Docker control** (FULL mode): Use `net don/doff` for container internet access
- **GDB** (FULL mode): Built from source with multi-arch support and custom patch
- **Snap removal**: Optional during installation with apt pinning
- **Font**: Terminator requires manual configuration to use Agave Nerd Font
