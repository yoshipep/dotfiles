# Development Environment Setup

Personal dotfiles repository with automated installation. Clone and run one script to get an identical development environment on any machine.

Supports **Ubuntu** and **Debian** (apt-based).

## Quick Start

```bash
bash install_env.sh
```

Choose a preset or pick components individually:

1. **personal** — full environment (everything below)
2. **dev-core** — shell + editor + tmux + cargo tools (non-invasive: no desktop/firewall/VMs/system services, but still needs root for apt + toolchain)
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
| `dev-core` | shell + Neovim + tmux + Alacritty + cargo tools + Go/Rust/Node — non-invasive (no desktop/firewall/VMs/services), still needs root for apt + toolchain |
| `config`   | dotfiles only, no installs (the floor; safe on locked-down boxes)                                        |

**Components** (custom menu)

- **Base**: `syspkgs-core` / `syspkgs-full` (apt), `config` (dotfiles floor)
- **Languages**: `rust`, `go`, `node`
- **Shell**: `shell` (zsh, oh-my-zsh, fzf), `plugins` (powerlevel10k, zsh-autosuggestions)
- **Editor**: `neovim`, `nvim-plugins` (headless PlugInstall/CoC/treesitter + a pynvim venv for the isort rplugin), `theme`, `treesitter-cli`, `cargo-tools` (eza, bat, ripgrep, git-delta, asm-lsp), `pipx-tools` (clangd, clang-format)
- **Terminal / Desktop**: `alacritty`, `font` (0xProto Nerd Font), `sway` (Wayland desktop: WM, waybar, gtklock, mako, fuzzel + wifi picker, mate-polkit, screenshots)
- **Dev tools**: `docker`, `libvirt` (QEMU/KVM + virt-manager), `gdb` (+ `gef-gep`), `ghidra`, `lazydocker`
- **Network**: `network` (firewall + static IP + systemd services)

On non-apt or no-sudo boxes, `syspkgs-*` are skipped; user-space components still run and assume their system deps are present (failing loudly if not).

**OS-version gate**: below the minimum (Ubuntu 24.04 / Debian 13), the GUI desktop and full-system components are withheld and only `config` + `dev-core` are offered — the toolchain and dotfiles work on older releases, the Sway/gtklock stack needs a recent OS. Override with `ALLOW_OLD_OS=1 bash install_env.sh`.

---

## Editor & Docs Workflow

- **Neovim**: LSP + CoC + treesitter, 8 themes.
- **Markdown / notes**: markview renders inline automatically (normal/insert/command modes; hybrid on insert shows raw source only on the line being edited). Browser preview via `markdown-preview.nvim` — `<leader>mp` opens one tab that follows the active buffer; `mkdnflow` navigates between note files (`<CR>` follow link, `<BS>`/`<Del>` history).
- **Sphinx**: `sphinx-serve [dir]` (or `:SphinxServe` / `<leader>sp` in nvim) — creates a per-project venv, installs its requirements, and live-reloads the build in the browser.
- **PDFs**: evince (vimtex viewer).

---

## Desktop — Sway (`sway` component / `personal` preset)

Wayland desktop ported from i3, themed gruvbox throughout:

- **sway** + **waybar** — workspaces and to-do (left); active-mode indicator (center — shows the `$mod+Shift+p` shutdown/reboot/lock menu, empty otherwise); wifi, memory, battery, firewall/docker status, pulseaudio, IP, hostname, clock (right). IP is the default-route source address (ignores `docker0`).
- **gtklock** lock screen (`$mod+l`) — GNOME-style: blurred wallpaper, big clock, clean centered entry. Driven by `scripts/lock.sh`; needs gtklock ≥ 4.0.0 for the styling (older apt versions lock unstyled). **swayidle** locks after 5 min, blanks the display 2 min later.
- **fuzzel** launcher (`$mod+d`) and wifi picker — clicking the waybar wifi icon runs `scripts/wifi-menu.sh` (nmcli networks in fuzzel, connect with a masked password prompt).
- **mako** notifications (per-urgency color/opacity, 5 s auto-close), **mate-polkit** auth agent, **gammastep** color temperature — all autostarted.
- **flameshot** screenshots via `xdg-desktop-portal-wlr` (which shells out to `grim`) — `$mod+x` region, `Print` fullscreen → `~/Pictures` + clipboard
- **VMs** — `Ctrl+Alt+v` picks a libvirt domain in fuzzel and opens it fullscreen in virt-viewer (`scripts/vm-menu.sh`). `Ctrl+Alt+Del` shuts down the VM in the focused window, `Ctrl+Alt+Shift+Del` forces it off (`scripts/vm-shutdown.sh`). Both binds are `--inhibited` so they still reach sway through virt-viewer's fullscreen keyboard grab — which also means the guest never receives `Ctrl+Alt+Del` itself (use virt-viewer's *Send key* menu). **Each guest needs `qemu-guest-agent` installed**; without it the shutdown falls back to the ACPI power button, which a guest with no `acpid` and no logind session ignores silently.
- terminal: **alacritty** (`Ctrl+Alt+t`)
- **wallpaper**: `swaybg` paints `~/wallpaper.{jpg,jpeg,png}` on the first frame (falls back to a solid color)

---

## Network Control (`network` component)

All network settings load at runtime from `/etc/network.conf` — never hardcoded. Edit with `net config` to apply changes everywhere at once.

### Commands

```bash
net on/off                  # Enable/disable host internet access
net don/doff                # Enable/disable internet for the internet-capable container class
net von/voff <n>            # Enable/disable egress for one vm bridge (mail|web|dev)
net vupdate <n> [mins|off]  # Lend a vm bridge http/https briefly, so apt works
net vpon/vpoff              # Connect/disconnect the VPN, and route everything permitted through it
net vprelay                 # Pick a relay (fuzzel), set it and reconnect
net status                  # Show current state, read back from the live ruleset
net check                   # Validate the ruleset without loading it
net config                  # Edit /etc/network.conf, reload Docker + firewall
net firewall                # Edit /etc/firewall.nft, check it, optionally reload
net vpn                     # Edit /etc/vpn.conf, optionally resync
net start                   # Reload the ruleset (atomic; removals apply too)
net flush                   # Reduce to deny-all (closed, not open); net start to restore
```

**Who may egress, and by which path, are separate questions.** `net on`, `net don` and `net von` say *who*. `net vpon`/`net vpoff` say *by which path* — VPN off routes everything out the WAN, VPN on routes everything permitted through the tunnel. The VPN switch grants egress to nobody: `net off` + `net don` + VPN on means containers egress through the tunnel while the host still gets nothing.

**There is no master switch.** `net off` empties a set read only in the output chain, so VMs and internet-capable containers keep their egress — those accepts live in the forward chain. A host showing "offline" can still be NAT'ing a VM's browser to the internet.

### Firewall Architecture

- nftables, in our own `table inet fw` (+ `table ip fwnat`) — Docker keeps its own tables and can't reorder ours
- `policy drop` on input, output and forward. IPv6 is denied outright in every hook, not left to grub
- Reloads are atomic, so editing a rule out of `/etc/firewall.nft` actually retracts it
- **The host is a server to nobody.** No service accepts at all — only ping, from the LAN and VMs. Containers can't reach the host, not even to ping their own gateway
- **SSH *out* to the LAN always works**, `net on` or `net off` — the one exception to "`net off` closes the LAN too", so cutting the internet never kills the SSH session you typed the command from
- VM isolation: three libvirt bridges (`vmmail`, `vmweb`, `vmdev`), each with its own role ports; cross-bridge and LAN traffic is dropped (DNS excepted)
- Containers cannot reach the vm bridges, in either toggle state
- `net don` grants the internet, never the LAN — DNS is the one exception, resolved through a LAN machine
- Toggles are named sets, so `net status` reads the live ruleset rather than a state file and cannot disagree with it
- Boot fails closed: a deny-all ruleset is installed before the real one is read
- Logs via NFLOG to `/var/log/ulog/firewall.log`, one rate-limited prefix per drop reason; multicast/broadcast is dropped silently so LAN chatter doesn't fill it

`./fw-test.sh` verifies the whole model — structural checks against the live ruleset plus behavioural probes through real containers and namespaces standing in for VMs. `./fw-deploy.sh` installs with validate-and-rollback; `./fw-restore.sh` is the way back.

### Docker Networking

Every container falls into one of three categories, and the category **is** the network it joins. Nothing else declares it.

| Category | Network | Internet | Host reaches it | Claude reaches it | Example |
|---|---|---|---|---|---|
| Internet-capable | `docker0` (default bridge) | yes, via `net don/doff` | no — `docker exec` only | no | `claude-code` |
| Shared | `devnet` | **never** | yes | yes | `wordpress_site` |
| Host-only | `hostnet` | **never** | yes | **no** | `opengrok` |

**Internet-capable** uses the default bridge plus an explicit resolver:

```yaml
network_mode: bridge
dns:
  - ${DNS_SERVER}
```

Default bridge + explicit DNS routes through the forward chain, which is what lets `net don/doff` gate this class end to end. Reached by `docker exec` only — publishing a port on it has no effect from the host, since `docker0` is deliberately absent from the host→container rule.

**Shared and host-only** are browsed at `http://localhost:PORT` and differ in exactly one thing: the Claude container attaches to `devnet` and is deliberately absent from `hostnet`. Put a stack on `devnet` when you want Claude working on it; put it on `hostnet` when it is for your eyes alone.

```yaml
    networks:
      - devnet        # or: hostnet

networks:
  devnet:
    external: true
```

**"No internet" is enforced, not conventional** — `devnet`/`hostnet` have no egress rule at all, so `net don` has nothing to hand them. Consequence: `apt`, `composer` and `wp plugin install` don't work inside them; update from the host.

**The split between the two is enforced too** — separate networks route rather than bridge between them, so cross-talk is dropped as RFC1918. Same-network traffic is untouched, so WordPress still finds its DB and Claude still finds WordPress.

**A container needing neither the internet nor a host-facing port declares nothing at all** — Compose's own `<project>_default` bridge gets no rule, so no egress and no host access, though siblings can still talk. `network_mode: none` if it needs no network at all. (A Compose property — bare `docker run` still lands on `docker0`.)

Both shared networks are external to every compose project and created once with pinned bridge names, because `firewall.nft` matches them by name:

```bash
docker network create --opt com.docker.network.bridge.name=br-devnet  devnet
docker network create --opt com.docker.network.bridge.name=br-hostnet hostnet
```

The host reaches those two on the ports in the `docker_ports` set — **container-side ports, not published ones**. A stack published as `127.0.0.1:8888:80` needs **80** in the set; Docker rewrites the destination in nat output before the filter chain runs, so adding `8888` does nothing at all. Only `8080` is there by default — add whatever else a new stack needs.

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
├── fw-deploy.sh                 # Install the ruleset to /etc (validate, load, rollback on failure)
├── fw-restore.sh                # Roll back to the pre-deploy backup
├── fw-test.sh                   # Firewall verification harness (structural + behavioural)
├── dotfiles/
│   ├── .zshrc                   # Zsh (oh-my-zsh, aliases, fzf; degrades without tools)
│   ├── .zshenv                  # Env vars (PATH, MAKEFLAGS, EDITOR, Wayland)
│   ├── .p10k.zsh                # Powerlevel10k prompt
│   ├── .tmux.conf               # Tmux (status bar collapses when waybar is present)
│   ├── .gdbinit                 # GDB settings + custom commands
│   ├── .gef.rc                  # GEF configuration
│   ├── .clang-format            # C/C++ formatter (8-space indent, 120 cols)
│   ├── .gitconfig               # Git (delta pager, histogram diffs)
│   ├── firewall.sh              # nftables loader (installed to /etc/)
│   ├── firewall.nft             # the ruleset itself (installed to /etc/)
│   ├── network-static.sh        # Static IP script (installed to /etc/)
│   ├── firewall.service         # Systemd service for firewall
│   ├── network-static.service   # Systemd service for static IP
│   ├── vpn-sync.rules           # udev: reconcile the egress path when a tunnel appears/goes
│   ├── ulogd.conf               # Firewall logging config
│   ├── libvirt/                 # VM network definitions (vmmail/vmweb/vmdev, open bridges)
│   └── .config/
│       ├── nvim/                # Neovim (LSP, CoC, treesitter, markview, markdown-preview, mkdnflow)
│       ├── alacritty/           # Alacritty (0xProto Nerd Font, tmux integration)
│       ├── sway/                # Sway WM config
│       ├── waybar/              # Waybar (config, style, to-do TUI)
│       ├── gtklock/             # Lock screen (config.ini, layout.xml, gruvbox style.css)
│       ├── mako/                # Notification daemon (gruvbox, per-urgency)
│       ├── fuzzel/              # Launcher + wifi picker theme (gruvbox)
│       ├── xdg-desktop-portal/  # Portal backends for Sway (screenshot/screencast)
│       └── environment.d/       # Session PATH (user bins for GUI-launched apps)
├── scripts/                     # Utility scripts (copied to ~/scripts/)
│   ├── net                      # Firewall control wrapper
│   ├── lock.sh                  # gtklock lock screen (blurred wallpaper)
│   ├── idle.sh                  # swayidle: lock then blank the display
│   ├── wifi-menu.sh             # fuzzel wifi picker (nmcli connect)
│   ├── vpn-menu.sh              # fuzzel VPN relay picker (the one provider-specific file)
│   ├── sphinx-serve.sh          # Live Sphinx docs preview (per-project venv)
│   ├── tmux_bar.sh              # tmux status segments (full on TTY/SSH, minimal under waybar)
│   ├── waybar_fw_status.sh      # Firewall status for waybar
│   ├── waybar_docker_status.sh  # Docker firewall status for waybar
│   ├── waybar_ip.sh             # LAN IP for waybar (default-route source)
│   ├── tmux-sessionizer.sh      # Session switcher: tmuxinator projects + dirs (prefix+f)
│   ├── seek                     # Hex dump at file offset
│   ├── sz                       # Print file size
│   └── opensocat                # Quick TCP listener on :9090
├── dockers/
│   ├── claude/                  # Claude Code container — internet-capable class, on docker0
│   └── opengrok/                # Code search on localhost:8080 — host-only class, on hostnet
└── patches/
    └── gdb.patch                # GDB hex escape sequences (pinned to GDB_TAG)
```

---

## Notes

- **SSH keys**: Not included — generate or transfer manually
- **network.conf**: Gitignored — never commit it
- **vpn.conf**: Lives at `/etc/vpn.conf`, untracked — provider values only; no firewall logic names a provider
- **Snap removal**: Optional during installation (`removesnap`, Ubuntu only)
- **Neovim theme**: Saved to `~/.vim_theme`, change anytime with `echo "gruvbox" > ~/.vim_theme`
- **Available themes**: molokai-dark, catppuccin, kanagawa, onedark, vscode, dracula, tokyodark, gruvbox
- **Alacritty**: Launches tmux directly as shell — opening a terminal always enters a tmux session
- **Assembly LSP**: Configure per-project with `.asm-lsp.toml`
