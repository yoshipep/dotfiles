#!/bin/bash

# ============================================================================
# USER CONFIGURATION - MODIFY THESE VARIABLES ACCORDING TO YOUR SETUP
# ============================================================================

# Network Interface: Auto-detected physical interface (usually correct)
# Run 'ip link' to verify your interface name if needed
INTERFACE=''

# Static IP Address: The IP you want assigned to this machine
# Example: "192.168.1.100"
STATIC_IP=''

# Network Mask: Subnet mask in CIDR notation
# Common values: 24 (255.255.255.0), 16 (255.255.0.0), 8 (255.0.0.0)
NETMASK=''

# Gateway: Your router's IP address
# Example: "192.168.1.1"
GATEWAY=''

# DNS Servers: DNS server IP (your router, Pi-hole, or public DNS like 8.8.8.8)
# Example: "192.168.1.1" or "8.8.8.8"
DNS_SERVERS=''

# ============================================================================
# END USER CONFIGURATION
# ============================================================================

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
