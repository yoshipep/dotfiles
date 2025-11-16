# Development Environment Setup Repository

This repository contains a bash script that downloads and configures all necessary packages to create a development
environment on **Ubuntu**. Dotfiles and configurations are organized within the repository.

## Structure

```
.
├── install_env.sh          # Main installation script
├── dotfiles/               # User configurations
│   ├── .zshrc, .p10k.zsh  # Shell configuration
│   ├── .clang-format      # C/C++ code formatting
│   ├── .gef.rc            # GDB Enhanced Features
│   ├── firewall.sh        # Firewall script
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

1. **Firewall** (`firewall.sh`): Configure DNS server and network interface name
   - Edit the `DNS` and `WAN_IFACE` variables at the beginning of the file
   - Adjust VM IPs and ports according to your configuration

2. **Static network** (`network-static.sh`): IP, gateway, and DNS

3. **IPv4 forwarding**: Enable in `/etc/sysctl.conf`

4. **IPv6**: Option to disable (dual-boot)

### SSH Configuration for VMs

SSH keys for connecting to VMs must be generated manually:

```bash
# Generate key for the VM
ssh-keygen -t ed25519 -f ~/.ssh/vbox_vm_name -C "vm-name"

# Copy the public key to the VM
ssh-copy-id -i ~/.ssh/vbox_vm_name.pub user@vm_ip
```

⚠️ **Security note**: Private keys are NOT included in this repository. The `.ssh/config` file contains references to keys that must be generated locally.
