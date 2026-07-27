# Development Environment Setup

Personal dotfiles repository with automated installation. Clone and run one script to get an identical development environment on any machine.

Supports **Ubuntu** and **Debian** (apt-based).

## Quick Start

```bash
bash install_env.sh
```

Choose a preset or pick components individually:

1. **personal** — full environment (everything below)
2. **dev-core** — shell + editor + tmux + cargo tools (corporate-friendly; no desktop/firewall)
3. **config** — deploy dotfiles only, no installs
4. **custom** — pick components by number (dependencies resolved automatically)

The installer detects root/apt capability and skips components it can't install. Some prompt further: the Neovim theme, and network settings for the `network` component.

---

## Installation

The installer is a component registry — each component declares whether it needs root and what it depends on. Picking a preset or a custom set resolves the full dependency closure and runs it in a safe order.

**Presets**

| Preset     | Contents                                                                                                 |
| ---------- | -------------------------------------------------------------------------------------------------------- |
| `personal` | everything: shell, editor, terminal, Sway desktop, dev tools, firewall                                   |
| `dev-core` | shell + Neovim + tmux + Alacritty + cargo tools + Go/Rust/Node — corporate-friendly, no desktop/firewall |
| `config`   | dotfiles only, no installs (the floor; safe on locked-down boxes)                                        |

**Components** (custom menu)

- **Base**: `syspkgs-core` / `syspkgs-full` (apt), `config` (dotfiles floor)
- **Languages**: `rust`, `go`, `node`
- **Shell**: `shell` (zsh, oh-my-zsh, fzf), `plugins` (powerlevel10k, zsh-autosuggestions)
- **Editor**: `neovim`, `nvim-plugins` (headless PlugInstall/CoC/treesitter), `theme`, `treesitter-cli`, `cargo-tools` (eza, bat, ripgrep, git-delta, asm-lsp), `pipx-tools` (clangd, clang-format)
- **Terminal / Desktop**: `alacritty`, `font` (0xProto Nerd Font), `sway` (Wayland desktop)
- **Dev tools**: `docker`, `virtualbox`, `gdb` (+ `gef-gep`), `ghidra`, `lazydocker`
- **Network**: `network` (firewall + static IP + systemd services)

On non-apt or no-sudo boxes, `syspkgs-*` are skipped; user-space components still run and assume their system deps are present (failing loudly if not).

---

## Editor & Docs Workflow

- **Neovim**: LSP + CoC + treesitter, 8 themes.
- **Markdown / notes**: browser preview via `markdown-preview.nvim` — `<leader>mp` opens one tab that follows the active buffer; `mkdnflow` navigates between note files (`<CR>` follow link, `<BS>`/`<Del>` history). markview renders inline on demand (`<leader>v` / `<leader>h`).
- **Sphinx**: `sphinx-serve [dir]` (or `:SphinxServe` / `<leader>sp` in nvim) — creates a per-project venv, installs its requirements, and live-reloads the build in the browser.
- **PDFs**: evince (vimtex viewer).

---

## Desktop — Sway (`sway` component / `personal` preset)

Wayland desktop ported from i3:

- **sway** + **waybar** (workspaces, memory, battery, firewall/docker status, pulseaudio, IP, clock, to-do)
- **fuzzel** launcher (`$mod+d`), **swaylock** / **swayidle**, **gammastep**
- **flameshot** screenshots via `xdg-desktop-portal-wlr` — `$mod+x` region, `Print` fullscreen → `~/Pictures` + clipboard
- terminal: **alacritty** (`Ctrl+Alt+t`)

---

## Network Control (`network` component)

All network settings load at runtime from `/etc/network.conf` — never hardcoded. Edit with `net config` to apply changes everywhere at once.

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

## GDB Custom Build (`gdb` component)

Built from source in `/opt/gdb`:

- `--enable-targets=all` — single binary, all architectures
- `patches/gdb.patch` — changes escape sequence display from octal (`\002`) to hex (`\x02`)

---

## Repository Structure

```
.
├── install_env.sh               # Main installer (à-la-carte component registry)
├── network.conf.example         # Network config template
├── dotfiles/
│   ├── .zshrc                   # Zsh (oh-my-zsh, aliases, fzf; degrades without tools)
│   ├── .zshenv                  # Env vars (PATH, MAKEFLAGS, EDITOR, Wayland)
│   ├── .p10k.zsh                # Powerlevel10k prompt
│   ├── .tmux.conf               # Tmux (status bar collapses when waybar is present)
│   ├── .gdbinit                 # GDB settings + custom commands
│   ├── .gef.rc                  # GEF configuration
│   ├── .clang-format            # C/C++ formatter (8-space indent, 120 cols)
│   ├── .gitconfig               # Git (delta pager, histogram diffs)
│   ├── firewall.sh              # iptables firewall (installed to /etc/)
│   ├── network-static.sh        # Static IP script (installed to /etc/)
│   ├── firewall.service         # Systemd service for firewall
│   ├── network-static.service   # Systemd service for static IP
│   ├── ulogd.conf               # Firewall logging config
│   └── .config/
│       ├── nvim/                # Neovim (LSP, CoC, treesitter, markdown-preview, mkdnflow)
│       ├── alacritty/           # Alacritty (0xProto Nerd Font, tmux integration)
│       ├── sway/                # Sway WM config
│       ├── waybar/              # Waybar (config, style, to-do TUI)
│       ├── xdg-desktop-portal/  # Portal backends for Sway (screenshot/screencast)
│       └── environment.d/       # Session PATH (user bins for GUI-launched apps)
├── scripts/                     # Utility scripts (copied to ~/scripts/)
│   ├── net                      # Firewall control wrapper
│   ├── sphinx-serve.sh          # Live Sphinx docs preview (per-project venv)
│   ├── tmux_bar.sh              # tmux status segments (full on TTY/SSH, minimal under waybar)
│   ├── waybar_fw_status.sh      # Firewall status for waybar
│   ├── waybar_docker_status.sh  # Docker firewall status for waybar
│   ├── tmux-sessionizer.sh      # Session switcher: tmuxinator projects + dirs (prefix+f)
│   ├── seek                     # Hex dump at file offset
│   ├── sz                       # Print file size
│   └── opensocat                # Quick TCP listener on :9090
├── dockers/
│   ├── claude/                  # Claude Code container (isolated via firewall)
│   └── opengrok/                # Code search on localhost:8080
└── patches/
    └── gdb.patch                # GDB hex escape sequences (pinned to GDB_TAG)
```

---

## Notes

- **SSH keys**: Not included — generate or transfer manually
- **network.conf**: Gitignored — never commit it
- **Snap removal**: Optional during installation (`removesnap`, Ubuntu only)
- **Neovim theme**: Saved to `~/.vim_theme`, change anytime with `echo "gruvbox" > ~/.vim_theme`
- **Available themes**: molokai-dark, catppuccin, kanagawa, onedark, vscode, dracula, tokyodark, gruvbox
- **Alacritty**: Launches tmux directly as shell — opening a terminal always enters a tmux session
- **Assembly LSP**: Configure per-project with `.asm-lsp.toml`
