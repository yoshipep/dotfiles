#!/usr/bin/env bash
# VM launcher for Sway: pick a libvirt domain with fuzzel, start it if it is
# stopped, and open its console fullscreen with virt-viewer (no virt-manager).
URI='qemu:///system'

vm=$(virsh -c "$URI" list --all --name | sed '/^$/d' |
	fuzzel --dmenu --prompt 'VM: ') || exit 0
[ -z "$vm" ] && exit 0

virsh -c "$URI" domstate "$vm" 2>/dev/null | grep -q running ||
	virsh -c "$URI" start "$vm"

exec virt-viewer -c "$URI" --full-screen \
	--hotkeys=release-cursor=ctrl+alt,toggle-fullscreen=shift+f11 "$vm"
