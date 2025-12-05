#!/bin/bash

# ============================================================================
# NETWORK CONFIGURATION - AUTO-GENERATED FROM network.conf
# ============================================================================
# These values are automatically substituted from network.conf during installation.
# Do not edit directly - modify network.conf and re-run install_env.sh instead.
# ============================================================================

INTERFACE='__WAN_IFACE__'
STATIC_IP='__HOST_IP__'
NETMASK='__NETMASK__'
GATEWAY='__GATEWAY__'
DNS_SERVERS='__DNS_SERVER__'

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
