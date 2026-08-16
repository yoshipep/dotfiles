#!/usr/bin/env bash
# Power off the VM shown in the focused window (no menu, no ambiguity when several
# virt-viewer windows are open). Bound to Ctrl+Alt+Del in the Sway config.
#   vm-shutdown.sh          -> ACPI shutdown, the guest closes cleanly
#   vm-shutdown.sh --force  -> destroy, equivalent to pulling the power cord
#
# GUEST REQUIREMENT: install qemu-guest-agent inside every VM
#   (apt install qemu-guest-agent && systemctl enable --now qemu-guest-agent)
# Without it the graceful path falls back to ACPI, which many guests ignore.
set -u
URI='qemu:///system'
# How long to wait for the guest to act on the ACPI request before saying so.
TIMEOUT=20

# Without this, a missing tool leaves $pid empty and the script blames the focused
# window instead of naming what is actually missing.
for dep in swaymsg jq virsh; do
      command -v "$dep" >/dev/null || {
              notify-send -u critical 'VM' "vm-shutdown.sh: $dep is not installed"
              exit 1
      }
done

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
      action=destroy
      args=(destroy)
      ok="$vm forced off"
else
      action=shutdown
      # Ask the guest agent first, fall back to the ACPI power button. ACPI alone
      # is unreliable: a guest with no acpid and no logind session never acts on
      # it, and virsh still reports success because libvirt only pressed the
      # button -- which is why the watch loop at the end of this script exists.
      args=(shutdown --mode agent,acpi)
      ok="Shutting down $vm..."
fi

# A failing virsh (polkit denial, user not in the libvirt group, domain already
# off) ended in silence: stderr goes nowhere when Sway runs this from a binding.
if ! err=$(virsh -c "$URI" "${args[@]}" "$vm" 2>&1 >/dev/null); then
      notify-send -u critical 'VM' "$action $vm failed: ${err:-unknown error}"
      exit 1
fi
notify-send 'VM' "$ok"

# destroy kills the domain synchronously, so there is nothing left to check.
[ "$action" = destroy ] && exit 0

# virsh only asks, so watch the domain: a guest sitting on a "really shut down?"
# dialog stays up, and otherwise the notification above is the only outcome.
elapsed=0
state=running
while [ "$elapsed" -lt "$TIMEOUT" ]; do
      sleep 1
      elapsed=$((elapsed + 1))
      state=$(virsh -c "$URI" domstate "$vm" 2>/dev/null | head -n1)
      case "$state" in
      'shut off' | crashed | '') exit 0 ;;
      esac
done

notify-send -u critical 'VM' \
      "$vm ignored the shutdown request (still \"$state\" after ${TIMEOUT}s). Ctrl+Alt+Shift+Del forces it off."
