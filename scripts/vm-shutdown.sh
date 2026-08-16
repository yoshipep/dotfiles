#!/usr/bin/env bash
# Power off the VM shown in the focused window (no menu, no ambiguity when several
# virt-viewer windows are open). Bound to Ctrl+Alt+Del in the Sway config.
#   vm-shutdown.sh          -> ACPI shutdown, the guest closes cleanly
#   vm-shutdown.sh --force  -> destroy, equivalent to pulling the power cord
set -u
URI='qemu:///system'

pid=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) |
	select(.focused == true) | .pid // empty')

# vm-menu.sh always passes the domain name as the last virt-viewer argument, so
# read it back from the process rather than parsing the window title.
if [ -z "$pid" ] || [ "$(cat "/proc/$pid/comm" 2>/dev/null)" != "virt-viewer" ]; then
	notify-send 'VM' 'Focused window is not a VM'
	exit 0
fi
vm=$(tr '\0' '\n' <"/proc/$pid/cmdline" | sed '/^$/d' | tail -n1)

if [ "${1:-}" = "--force" ]; then
	virsh -c "$URI" destroy "$vm" && notify-send 'VM' "$vm forced off"
else
	virsh -c "$URI" shutdown "$vm" && notify-send 'VM' "Shutting down $vm..."
fi
