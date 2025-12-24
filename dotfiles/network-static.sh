#!/bin/bash

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================
# Load network configuration from system-wide location
# To change network settings, run: net config
# ============================================================================

CONFIG_FILE="/etc/network.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[!] ERROR: Network configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

INTERFACE="$WAN_IFACE"
STATIC_IP="$HOST_IP"
NETMASK="${NETMASK:-24}"
GATEWAY="$GATEWAY"
DNS_SERVERS="$DNS_SERVER"

do_start() {
    echo "[+] Setting static IP ${STATIC_IP}/${NETMASK} on ${INTERFACE}"

    # Remove existing IP addresses
    ip addr flush dev "${INTERFACE}"

    # Set static IP
    ip addr add "${STATIC_IP}/${NETMASK}" dev "${INTERFACE}"

    # Bring interface up
    ip link set "${INTERFACE}" up

    # Set default gateway
    ip route add default via "${GATEWAY}" dev "${INTERFACE}" 2>/dev/null || true

    # Configure DNS (if systemd-resolved is not managing it)
    if [ ! -L /etc/resolv.conf ] || [ ! -e /etc/resolv.conf ]; then
        echo "nameserver ${DNS_SERVERS}" > /etc/resolv.conf
    fi

    echo "[+] Network configuration applied"
}

do_stop() {
    echo "[+] Flushing IP configuration on ${INTERFACE}"
    ip addr flush dev "${INTERFACE}"
    ip link set "${INTERFACE}" down
}

check_root() {
        ## Check root perms
        if [[ $EUID -ne 0 ]]; then
                echo "[-] Error: Firewall must be executed as root" >&2
                exit 1
        fi
}

# ----------------------------------------------------------------------------------- #

check_root
case "$1" in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    restart)
        do_stop
        sleep 1
        do_start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}" >&2
        exit 1
        ;;
esac

exit 0
