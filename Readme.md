# Development Environment Setup Repository

This repository contains a bash script that downloads and configures all necessary packages to create a development
environment on **Ubuntu**. Dotfiles and configurations are organized within the repository.

## Structure

```
.
├── install_env.sh          # Main installation script
├── network.conf.example    # Network configuration template
├── dotfiles/               # User configurations
│   ├── .zshrc, .p10k.zsh  # Shell configuration
│   ├── .clang-format      # C/C++ code formatting
│   ├── .gef.rc            # GDB Enhanced Features
│   ├── firewall.sh        # Firewall script (auto-configured)
│   ├── network-static.sh  # Static IP script (auto-configured)
│   └── .config/           # Application configurations
│       ├── nvim/          # Neovim
│       ├── terminator/    # Terminator
│       └── coc/           # Conquer of Completion
├── scripts/               # Utility scripts
├── patches/               # Patches (e.g., gdb.patch)
└── dockers/               # Docker Compose configurations
```

## Usage

```bash
bash install_env.sh
```

The script will automatically install:
- Terminal: terminator
- Shell: zsh, oh-my-zsh, fzf, eza
- Extras: ghidra, neovim, batcat, ripgrep
- Font: Agave Nerd Font
- Plugins: powerlevel10k, zsh-autosuggestions, vim-plug, coc

### Configuration Required During Installation

During script execution, you will be prompted to configure:

1. **Network settings** (`network.conf`): Single configuration file for all network settings
   - `DNS_SERVER`: Your DNS server IP (Pi-hole, router, or 8.8.8.8)
   - `HOST_IP`: This machine's static IP address
   - `GATEWAY`: Your router's IP address
   - `NETMASK`: Network mask (default: 24)
   - `WAN_IFACE`: Leave empty for auto-detection

   The installer automatically applies these values to firewall.sh, network-static.sh, and Docker containers.

2. **IPv4 forwarding**: Enable in `/etc/sysctl.conf`

3. **IPv6**: Option to disable (dual-boot)

### SSH Configuration for VMs

SSH keys for connecting to VMs must be generated manually:

```bash
# Generate key for the VM
ssh-keygen -t ed25519 -f ~/.ssh/vbox_vm_name -C "vm-name"

# Copy the public key to the VM
ssh-copy-id -i ~/.ssh/vbox_vm_name.pub user@vm_ip
```

⚠️ **Security note**: Private keys are NOT included in this repository. The `.ssh/config` file contains references to keys that must be generated locally.

### Firewall and Network Control

The environment includes a custom iptables firewall with granular network control:

**Control Commands** (via `scripts/net`):
- `net on/off`: Enable/disable host internet access
- `net don/doff`: Enable/disable Docker container internet access
- `net enable/disable`: Enable/disable firewall
- `net start`: Reload firewall rules

**Docker Network Integration**: Containers requiring internet access must use:
```yaml
network_mode: bridge    # Use default docker0 bridge
dns:
  - __DNS_SERVER__      # Explicit DNS (auto-substituted from network.conf)
```

This configuration routes all container traffic through the firewall's FORWARD chain, allowing `net don/doff` to control Docker internet access.
