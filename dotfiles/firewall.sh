#!/bin/bash

# set -x

IPTABLES=/usr/sbin/iptables

# ============================================================================
# NETWORK CONFIGURATION - AUTO-GENERATED FROM network.conf
# ============================================================================
# These values are automatically substituted from network.conf during installation.
# Do not edit directly - modify network.conf and re-run install_env.sh instead.
# ============================================================================

DNS='__DNS_SERVER__'
WAN_IFACE='__WAN_IFACE__'
PC='__HOST_IP__'

# -- PORTS --
SSH_PORT='22'
DNS_PORT='53'
HTTP_PORT='80'
HTTPS_PORT='443'

# -- MAIL VMs --
MAIL_IFACE='vboxnet0'
MAIL_ROUTER='192.168.3.193'
IONOS_VM='192.168.3.194'
GMAIL_VM='192.168.3.195'
IONOS_PORTS='993,587'
GMAIL_PORTS='993,465,443'

# -- WEB NAVIGATION VMs --
WEB_IFACE='vboxnet1'
WEB_ROUTER='192.168.4.193'
WEB_VM='192.168.4.194'
CLAUDE_VM='192.168.4.195'
WEB_PORTS="${HTTP_PORT},${HTTPS_PORT}"
CLAUDE_PORTS="${SSH_PORT},${WEB_PORTS}"

# -- DEVELOP VMs --
DEVELOP_IFACE='vboxnet2'
DEVELOP_ROUTER='192.168.5.1'
OSDEV_VM='192.168.5.2'
OSDEV_PORTS="${WEB_PORTS}"

# -- LAN --
HOST_PORTS="${WEB_PORTS}"

# -- DOCKERS --
OPENGROK_PORT='8080'
DOCKER_PORTS="${OPENGROK_PORT}"

# Silent mode: suppress output messages when called with 'silent' as second argument
if [[ $2 == 'silent' ]]; then
        SILENT='>/dev/null'
else
        SILENT=''
fi

do_flush_all_chains() {
    # Deleting all the chains may break externally managed chains (i.e.: Docker chains) 
    # Some services must be restarted after this (Docker)
    TABLES=('nat' 'mangle' 'security' 'raw' 'filter')
    for table in "${TABLES[@]}"; do
    ${IPTABLES} -t "$table" -F
    ${IPTABLES} -t "$table" -Z
    ${IPTABLES} -t "$table" -X
    done
    echo '0' > /etc/.fw_status
}

# Set default policy to ACCEPT (firewall disabled, all traffic allowed)
def_policy_accept() {
    ${IPTABLES} -F
    ${IPTABLES} -P INPUT ACCEPT
    ${IPTABLES} -P OUTPUT ACCEPT
    ${IPTABLES} -P FORWARD ACCEPT
    echo '0' > /etc/.fw_status
}

# Set default policy to DROP (firewall enabled, deny by default)
def_policy_drop() {
    ${IPTABLES} -F
    ${IPTABLES} -P INPUT DROP
    ${IPTABLES} -P OUTPUT DROP
    ${IPTABLES} -P FORWARD DROP
    echo '1' > /etc/.fw_status
}

# Enable network access for the host PC only (web browsing, DNS)
do_enable_host_net() {
    # Allow all NEW outbound connections from the host
    append_rule "OUTPUT -s ${PC} -m conntrack --ctstate NEW -j ACCEPT"

    # Allow specific outbound web and DNS traffic (redundant with above, but kept for clarity)
    append_rule "OUTPUT -p tcp -s ${PC} --match multiport --dports ${HOST_PORTS} -j ACCEPT"
    append_rule "OUTPUT -p udp -s ${PC} --match multiport --dports ${DNS_PORT},${HTTPS_PORT} -j ACCEPT"

    # Remove the TCP reject fallback rule to allow connections through
    remove_rule 'INPUT -p tcp -j REJECT --reject-with tcp-reset'
    echo '0' > /etc/.fw_status
}

# Disable network access for the host PC only (lock down to minimal access)
do_disable_host_net() {
    # Revert rules from do_enable_host_net
    remove_rule "OUTPUT -s ${PC} -m conntrack --ctstate NEW -j ACCEPT"
    remove_rule "OUTPUT -p tcp -s ${PC} --match multiport --dports ${HOST_PORTS} -j ACCEPT"
    remove_rule "OUTPUT -p udp -s ${PC} --match multiport --dports ${DNS_PORT},${HTTPS_PORT} -j ACCEPT"

    # Re-add the TCP reject fallback rule for better connection refusal behavior
    append_rule 'INPUT -p tcp -j REJECT --reject-with tcp-reset'
    echo '1' > /etc/.fw_status
}

# Enable network access for Docker containers only (web browsing, all ports)
do_enable_docker_net() {
    # First, remove the DROP rules for Docker traffic
    remove_rule "FORWARD -i docker+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j DROP"
    remove_rule "FORWARD -i br-+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j DROP"

    # Allow Docker containers to initiate NEW outbound connections
    # Docker uses bridge interfaces like docker0, br-xxxxx
    # INSERT at top to override Docker's default rules
    insert_rule "FORWARD -i docker+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j ACCEPT"
    insert_rule "FORWARD -i br-+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j ACCEPT"

    # Allow return traffic from WAN to Docker networks
    insert_rule "FORWARD -i ${WAN_IFACE} -o docker+ -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    insert_rule "FORWARD -i ${WAN_IFACE} -o br-+ -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"

    # Note: MASQUERADE rule already handles NAT for Docker traffic
    echo '2' > /etc/.fw_status
}

# Disable network access for Docker containers only
do_disable_docker_net() {
    # Remove the ACCEPT rules from do_enable_docker_net
    remove_rule "FORWARD -i docker+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j ACCEPT"
    remove_rule "FORWARD -i br-+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j ACCEPT"
    remove_rule "FORWARD -i ${WAN_IFACE} -o docker+ -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    remove_rule "FORWARD -i ${WAN_IFACE} -o br-+ -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"

    # Re-add the DROP rules to block Docker traffic
    # INSERT at top to override Docker's default rules
    insert_rule "FORWARD -i docker+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j DROP"
    insert_rule "FORWARD -i br-+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j DROP"
    echo '1' > /etc/.fw_status
}

# Idempotent rule addition: only adds rule if it doesn't already exist
append_rule() {
    eval "iptables -C $1 >/dev/null 2>&1" || eval "iptables -A $1"
}

# Idempotent rule insertion: only inserts rule at top if it doesn't already exist
insert_rule() {
    eval "iptables -C $1 >/dev/null 2>&1" || eval "iptables -I $1"
}

# Safe rule removal: only removes rule if it exists
remove_rule() {
    eval "iptables -C $1 >/dev/null 2>&1" && eval "iptables -D $1"
}

# Main firewall initialization: sets up all iptables rules for locked-down configuration
do_start() {
    # Disable multicast on WAN interface to reduce network noise
    ip link set dev "${WAN_IFACE}" multicast off

    # Set default policies to DROP (deny all unless explicitly allowed)
    ${IPTABLES} -P INPUT DROP
    ${IPTABLES} -P OUTPUT DROP
    ${IPTABLES} -P FORWARD DROP

    # Allow all loopback traffic (required for local processes)
    append_rule "INPUT -i lo -j ACCEPT"
    append_rule "OUTPUT -o lo -j ACCEPT"

    # Allow ICMP echo-request (ping) with rate limiting
    append_rule "INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT"
    append_rule "OUTPUT -p icmp -j ACCEPT"
    append_rule "FORWARD -p icmp -j ACCEPT"

    # Allow host to connect to Docker containers on bridge interfaces
    append_rule "OUTPUT -o br+ -p tcp --match multiport --dports ${DOCKER_PORTS} -j ACCEPT"

    # Allow host to SSH to VMs on VirtualBox interfaces
    append_rule "OUTPUT -o vboxnet+ -p tcp --dport ${SSH_PORT} -j ACCEPT"

    # Drop invalid packets before processing
    append_rule "INPUT -m conntrack --ctstate INVALID -j DROP"
    append_rule "OUTPUT -m conntrack --ctstate INVALID -j DROP"
    append_rule "FORWARD -m conntrack --ctstate INVALID -j DROP"

    # Allow ESTABLISHED and RELATED connections (return traffic for existing connections)
    append_rule "INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    append_rule "OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    append_rule "FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"

    # Drop all incoming connection attempts (this is a client-only host)
    append_rule "INPUT -p tcp --syn -j DROP"

    # -- DOCKER BLOCKING (default: no internet for Docker) --
    # Block Docker containers from accessing the internet by default
    # INSERT these rules at the top so they come before Docker's own rules
    insert_rule "FORWARD -i docker+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j DROP"
    insert_rule "FORWARD -i br-+ -o ${WAN_IFACE} -m conntrack --ctstate NEW -j DROP"

    # -- VM FORWARDING RULES --
    # Allow Mail VMs to initiate outbound connections to specific ports (IMAP/SMTP)
    append_rule "FORWARD -p tcp -i ${MAIL_IFACE} -o ${WAN_IFACE} -s ${IONOS_VM} --match multiport --dports ${IONOS_PORTS} -m conntrack --ctstate NEW -j ACCEPT"
    append_rule "FORWARD -p tcp -i ${MAIL_IFACE} -o ${WAN_IFACE} -s ${GMAIL_VM} --match multiport --dports ${GMAIL_PORTS} -m conntrack --ctstate NEW -j ACCEPT"
    append_rule "FORWARD -i ${WAN_IFACE} -o ${MAIL_IFACE} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"

    # Allow Web VM to initiate outbound connections to HTTP/HTTPS ports
    append_rule "FORWARD -p tcp -i ${WEB_IFACE} -o ${WAN_IFACE} -s ${WEB_VM} --match multiport --dports ${WEB_PORTS} -m conntrack --ctstate NEW -j ACCEPT"
    append_rule "FORWARD -p tcp -i ${WEB_IFACE} -o ${WAN_IFACE} -s ${CLAUDE_VM} --match multiport --dports ${CLAUDE_PORTS} -m conntrack --ctstate NEW -j ACCEPT"
    append_rule "FORWARD -i ${WAN_IFACE} -o ${WEB_IFACE} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"

    # Allow Development VM to initiate outbound SSH connections
    append_rule "FORWARD -p tcp -i ${DEVELOP_IFACE} -o ${WAN_IFACE} -s ${OSDEV_VM} --match multiport --dports ${OSDEV_PORTS} -m conntrack --ctstate NEW -j ACCEPT"
    append_rule "FORWARD -i ${WAN_IFACE} -o ${DEVELOP_IFACE} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"

    # -- DNS FORWARDING FOR VMs --
    # VMs use their router IP as DNS server, which we redirect to the actual DNS server
    # Pattern: PREROUTING DNAT (redirect to DNS) -> FORWARD (allow) -> POSTROUTING MASQUERADE (NAT reply)

    # Mail VMs DNS forwarding
    append_rule "PREROUTING -t nat -p udp --dport ${DNS_PORT} -d ${MAIL_ROUTER} -j DNAT --to-destination ${DNS}"
    append_rule "FORWARD -p udp -s ${IONOS_VM} --dport ${DNS_PORT} -j ACCEPT"
    append_rule "POSTROUTING -t nat -p udp --sport ${DNS_PORT} -d ${IONOS_VM} -j MASQUERADE"
    append_rule "FORWARD -p udp -s ${GMAIL_VM} --dport ${DNS_PORT} -j ACCEPT"
    append_rule "POSTROUTING -t nat -p udp --sport ${DNS_PORT} -d ${GMAIL_VM} -j MASQUERADE"

    # Web VMs DNS forwarding
    append_rule "PREROUTING -t nat -p udp --dport ${DNS_PORT} -d ${WEB_ROUTER} -j DNAT --to-destination ${DNS}"
    append_rule "FORWARD -p udp -s ${WEB_VM} --dport ${DNS_PORT} -j ACCEPT"
    append_rule "POSTROUTING -t nat -p udp --sport ${DNS_PORT} -d ${WEB_VM} -j MASQUERADE"
    append_rule "FORWARD -p udp -s ${CLAUDE_VM} --dport ${DNS_PORT} -j ACCEPT"
    append_rule "POSTROUTING -t nat -p udp --sport ${DNS_PORT} -d ${CLAUDE_VM} -j MASQUERADE"

    # Development VM DNS forwarding
    append_rule "PREROUTING -t nat -p udp --dport ${DNS_PORT} -d ${DEVELOP_ROUTER} -j DNAT --to-destination ${DNS}"
    append_rule "FORWARD -p udp -s ${OSDEV_VM} --dport ${DNS_PORT} -j ACCEPT"
    append_rule "POSTROUTING -t nat -p udp --sport ${DNS_PORT} -d ${OSDEV_VM} -j MASQUERADE"

    # NAT for all outbound WAN traffic from VMs
    append_rule "POSTROUTING -t nat -o ${WAN_IFACE} -j MASQUERADE"

    # Allow SSH on the host (outbound only)
    append_rule "OUTPUT -p tcp -s ${PC} --dport ${SSH_PORT} -j ACCEPT"

    # Allow QUIC protocol (UDP/443) for Web, Claude and Gmail VMs (HTTP/3)
    append_rule "FORWARD -p udp -s ${WEB_VM} --match multiport --dports ${HTTPS_PORT} -j ACCEPT"
    append_rule "FORWARD -p udp -s ${CLAUDE_VM} --match multiport --dports ${HTTPS_PORT} -j ACCEPT"
    append_rule "FORWARD -p udp -s ${GMAIL_VM} --dport ${HTTPS_PORT} -j ACCEPT"

    # -- PORT SCAN DETECTION --
    # Drop suspicious TCP flag combinations used in port scanning
    append_rule "INPUT -p tcp --tcp-flags ALL NONE -j DROP"  # NULL scan
    append_rule "INPUT -p tcp --tcp-flags ALL ALL -j DROP"   # XMAS scan
    append_rule "INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP"
    append_rule "INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP"

    # -- FALLBACK RULES (catch-all for unmatched traffic) --
    # Log dropped packets to dedicated file via ulogd2 (see /var/log/ulog/firewall.log)
    # Uses NFLOG to avoid polluting dmesg/kernel logs
    append_rule 'INPUT -j NFLOG --nflog-group 1 --nflog-prefix "INPUT DROP: "'
    append_rule 'OUTPUT -j NFLOG --nflog-group 1 --nflog-prefix "OUTPUT DROP: "'
    append_rule 'FORWARD -j NFLOG --nflog-group 1 --nflog-prefix "FORWARD DROP: "'
    # Reject TCP connections with RST (cleaner than silent drop)
    append_rule "INPUT -p tcp -j REJECT --reject-with tcp-reset"
    echo '1' > /etc/.fw_status
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
    start|restart)
                eval "echo '[+] Firewall: loading custom iptables rules' $SILENT"
        do_start
        ;;
    enable-net)
        eval "echo '[!] Firewall: WARNING! Enabling external traffic in host!' $SILENT"
        do_enable_host_net
        ;;
    disable-net)
        eval "echo '[+] Firewall: Disabling traffic in the host' $SILENT"
        do_disable_host_net
        ;;
    enable-docker-net)
        eval "echo '[+] Firewall: Enabling external traffic for Docker containers' $SILENT"
        do_enable_docker_net
        ;;
    disable-docker-net)
        eval "echo '[+] Firewall: Disabling external traffic for Docker containers' $SILENT"
        do_disable_docker_net
        ;;
    flush)
        eval "echo '[+] Firewall: WARNING! Flushing all IPTables chains. Some services may be broken or need a restart (i.e.: docker)' $SILENT"
        do_flush_all_chains
        ;;
    enable)
        eval "echo '[+] Firewall: Changed default policy to DROP!' $SILENT"
        def_policy_drop
        ;;
    disable)
        eval "echo '[!] Firewall: Changed default policy to ACCEPT!' $SILENT"
        def_policy_accept
        ;;
    *)
        echo "Usage: $0 start|restart|enable-net|disable-net|enable-docker-net|disable-docker-net|flush|enable|disable" >&2
        exit 1
        ;;
esac

exit 0
