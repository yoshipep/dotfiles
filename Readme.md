# Development Environment Setup

Personal dotfiles repository with automated installation. Clone and run one script to get an identical development environment on any machine.

Supports **Ubuntu** and **Debian**.

## Quick Start

```bash
bash install_env.sh
```

The installer prompts for:
1. **Installation mode** (FULL or MINIMAL)
2. **Neovim theme** (8 options)
3. **Network configuration** (FULL mode only)

---

## Installation Modes

### FULL Mode

Complete environment for personal systems:

- **Shell**: zsh, oh-my-zsh, powerlevel10k, fzf, eza
- **Terminal**: Alacritty, tmux, tmuxinator
- **Editor**: Neovim with LSP, treesitter, CoC, and 8 themes
- **Development**: GDB (custom multi-arch build), Ghidra, Docker, VirtualBox
- **Network**: Custom firewall with VM isolation, static IP, systemd services
- **Tools**: batcat, ripgrep, git-delta, lazydocker, tree-sitter, asm-lsp, KeePassXC
- **Python**: virtualenvwrapper, autopep8, isort, ipython
- **Build**: Go, Rust/Cargo, Node.js, TeX Live, OpenJDK

### MINIMAL Mode

Essential dotfiles for corporate or restricted environments:

- **Shell**: zsh, oh-my-zsh, powerlevel10k, fzf, eza
- **Terminal**: Alacritty, tmux, tmuxinator
- **Editor**: Neovim with LSP, treesitter, CoC, and 8 themes
- **Tools**: batcat, ripgrep, clangd, clang-format, shellcheck, tree-sitter, asm-lsp
- **Build**: Go, Rust/Cargo, Node.js

**Skips**: GDB build, Docker, VirtualBox, Ghidra, firewall, TeX Live, system services, git-delta, lazydocker, KeePassXC, ipython, virtualenvwrapper

---

## Network Control (FULL Mode)

All network settings are loaded at runtime from `/etc/network.conf` — never hardcoded. Edit with `net config` to apply changes everywhere at once.

### Commands

```bash
net on/off        # Enable/disable host internet access
net don/doff      # Enable/disable Docker container internet access
net status        # Show current host and Docker network state
net config        # Edit /etc/network.conf, reload Docker + firewall
net firewall      # Edit /etc/firewall.sh and optionally reload
net start         # Reload firewall rules
net flush         # Flush all iptables rules (emergency reset)
```

### Firewall Architecture

- Default DROP on INPUT, OUTPUT, FORWARD chains
- VM isolation: three virtual networks (vboxnet0: mail, vboxnet1: web, vboxnet2: dev)
- Port scan detection (NULL, XMAS, malformed flags)
- Firewall logs via NFLOG to `/var/log/ulog/firewall.log`

### Docker Networking

Containers needing internet access must use default bridge + explicit DNS:

```yaml
network_mode: bridge
dns:
  - ${DNS_SERVER}
```

This routes traffic through the firewall's FORWARD chain, so `net don/doff` controls container internet access. User-defined bridge networks bypass the firewall.

---

## GDB Custom Build (FULL Mode)

Built from source in `/opt/gdb`:
- `--enable-targets=all` — single binary, all architectures
- `patches/gdb.patch` — changes escape sequence display from octal (`\002`) to hex (`\x02`)

---

## Repository Structure

```
.
├── install_env.sh              # Main installer
├── network.conf.example        # Network config template
├── dotfiles/
│   ├── .zshrc                 # Zsh config (oh-my-zsh, aliases, fzf)
│   ├── .zshenv                # Env vars (PATH, MAKEFLAGS, EDITOR, Rust)
│   ├── .p10k.zsh              # Powerlevel10k prompt
│   ├── .tmux.conf             # Tmux config
│   ├── .gdbinit               # GDB settings + custom commands
│   ├── .gef.rc                # GEF configuration
│   ├── .clang-format          # C/C++ formatter (8-space indent, 120 cols)
│   ├── .gitconfig             # Git config (delta pager, histogram diffs)
│   ├── firewall.sh            # iptables firewall (installed to /etc/)
│   ├── network-static.sh      # Static IP script (installed to /etc/)
│   ├── firewall.service       # Systemd service for firewall
│   ├── network-static.service # Systemd service for static IP
│   ├── ulogd.conf             # Firewall logging config
│   └── .config/
│       ├── nvim/              # Neovim (plugins, LSP, CoC, snippets, themes)
│       ├── alacritty/         # Alacritty (Agave Nerd Font, tmux integration)
│       └── .claude/           # Claude Code settings, statusline, agents
├── scripts/                    # Utility scripts (copied to ~/scripts/)
│   ├── net                    # Firewall control wrapper
│   ├── tmux_sessions.sh       # Session list for tmux status bar
│   ├── waybar_fw_status.sh    # Firewall status for Waybar
│   ├── waybar_docker_status.sh# Docker status for Waybar
│   ├── power_menu.sh          # Wofi power menu
│   ├── seek                   # Hex dump at file offset
│   ├── sz                     # Print file size
│   └── opensocat              # Quick TCP listener on :9090
├── dockers/
│   ├── claude/                # Claude Code container (isolated via firewall)
│   └── opengrok/              # Code search on localhost:8080
└── patches/
    ├── gdb.patch              # GDB hex escape sequences
    └── gef.patch              # GEF opcode spacing
```

---

## Notes

- **SSH keys**: Not included — generate or transfer manually
- **network.conf**: Gitignored — never commit it
- **Snap removal**: Optional during installation (Ubuntu only)
- **Neovim theme**: Saved to `~/.vim_theme`, change anytime with `echo "gruvbox" > ~/.vim_theme`
- **Available themes**: molokai-dark, catppuccin, kanagawa, onedark, vscode, dracula, tokyodark, gruvbox
- **Alacritty**: Launches tmux directly as shell — opening a terminal always enters a tmux session
- **Assembly LSP**: Configure per-project with `.asm-lsp.toml`
