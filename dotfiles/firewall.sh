#!/usr/bin/env bash
#
# Loads /etc/firewall.nft, prepending the site-specific defines from
# /etc/network.conf. nft replaces our tables in one atomic transaction, so a reload
# applies removals too -- editing a rule out of the file and reloading retracts it.

NFT=/usr/sbin/nft
RULES=/etc/firewall.nft
CONFIG_FILE=/etc/network.conf
VPN_CONFIG=/etc/vpn.conf
STATE=/run/firewall.state
INTENT=/run/firewall.intent
LOCK=/run/firewall.lock

# Site config lands here; see /etc/network.conf.
REQUIRED=(DNS_SERVER HOST_IP GATEWAY WAN_IFACE LAN_NET)

# VM topology, single source of truth: rendered into $RULES as defines, and read by
# vm_subnet for the conntrack flush. iface / subnet / router address.
VM_NETS=( "vmmail 10.0.1.0/24 10.0.1.1"
          "vmweb  10.0.2.0/24 10.0.2.1"
          "vmdev  10.0.3.0/24 10.0.3.1" )

# Default grant length for `net vupdate` -- long enough for a slow apt upgrade, short
# enough that forgetting to revoke one isn't a standing hole. A default, not a limit.
VM_UPDATE_MINUTES=15

die() { echo "[-] Firewall: $*" >&2; exit 1; }

check_root() { [[ $EUID -eq 0 ]] || die "must be executed as root"; }

# -- serialisation ----------------------------------------------------------------
# Taken by anything that mutates intent or the sets, so overlapping udev-fired
# `vpn-sync-settle` runs (add, then change) can't race each other's flush/refill and
# leave a set matching neither intent nor the kernel. Nests safely within one process.
lock_take() { exec 9>"$LOCK" && flock 9; }
lock_drop() { flock -u 9 2>/dev/null; return 0; }

# -- settle single-flight ---------------------------------------------------------
# A second lock held for the whole settle loop, unlike $LOCK which is per-mutation -- so
# a `net off` typed mid-connect can interrupt rather than wait 20s. Up to three settles
# fire per connect (net vpon, udev add, udev change) and would otherwise pile up
# harmlessly but wastefully. udev's invocations pass --skip-if-busy and leave if one is
# already running; `net vpon` waits, since it needs the answer.
SETTLE_LOCK=/run/firewall.settle.lock
settle_take() {
    exec 8>"$SETTLE_LOCK" || return 1
    if [[ "$1" == "--skip-if-busy" ]]; then flock -n 8; else flock 8; fi
}

load_config() {
    [[ -f "$CONFIG_FILE" ]] || die "configuration not found: $CONFIG_FILE"
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"

    local missing=()
    local v
    for v in "${REQUIRED[@]}"; do
        [[ -n "${!v}" ]] || missing+=("$v")
    done
    ((${#missing[@]})) && die "not set in ${CONFIG_FILE}: ${missing[*]}"

    # Caught here, not as an nft parse error later: NETMASK supplies the prefix, so a
    # prefix already in LAN_NET yields e.g. .../27/27.
    [[ "$LAN_NET" == */* ]] && die "LAN_NET must be a bare network address (no /prefix); NETMASK supplies it"

    NETMASK="${NETMASK:-24}"

    # Optional, and separate from network.conf on purpose: that file is topology (changes
    # when the machine moves), this is the provider (doesn't). Absent means no vpn here.
    # shellcheck disable=SC1090
    [[ -f "$VPN_CONFIG" ]] && source "$VPN_CONFIG"
    return 0
}

# Deny-all installed before the real load. nft applies atomically, so a file that fails
# to parse leaves whatever was loaded before it -- empty at boot, i.e. wide open. This
# makes the fallback closed instead.
deny_all() {
    ${NFT} -f - <<'EOF'
table inet fw
delete table inet fw
# fwnat goes too, so the fallback is complete rather than deny-all filtering next to a
# stale masquerade/dnat left over from the last good load.
table ip fwnat
delete table ip fwnat
table inet fw {
    chain input {
        type filter hook input priority filter; policy drop;
        meta nfproto ipv6 drop
        iif lo accept
        ct state established,related accept
    }
    chain forward {
        type filter hook forward priority filter; policy drop;
    }
    chain output {
        type filter hook output priority filter; policy drop;
        meta nfproto ipv6 drop
        oif lo accept
        ct state established,related accept
    }
}
EOF
}

render() {
    cat <<EOF
define WAN = "${WAN_IFACE}"
define LAN = ${LAN_NET}/${NETMASK}
define HOST_ADDR = ${HOST_IP}
define MAIL_NET    = $(vm_field vmmail 2)
define MAIL_ROUTER = $(vm_field vmmail 3)
define WEB_NET     = $(vm_field vmweb 2)
define WEB_ROUTER  = $(vm_field vmweb 3)
define DEV_NET     = $(vm_field vmdev 2)
define DEV_ROUTER  = $(vm_field vmdev 3)
EOF
    cat "$RULES"
}

do_start() {
    [[ -f "$RULES" ]] || die "ruleset not found: $RULES"
    render | ${NFT} -f - || die "ruleset failed to load; the deny-all fallback is active"
    return 0
}

do_check() { [[ -f "$RULES" ]] || die "ruleset not found: $RULES"; render | ${NFT} -c -f -; }

# Reduces us to deny-all rather than removing us: deleting the tables would leave nothing
# filtering at all. Docker's tables are untouched, so it needs no restart. For genuine
# removal see nft-rollback.sh.
do_flush() {
    deny_all || return 1
    ${NFT} delete table ip fwnat 2>/dev/null
    return 0
}

# -- toggles: set membership, not rule surgery ------------------------------------
# The rules reading these sets are permanent, so a toggle cannot desync from them.

set_add() { ${NFT} add element inet fw "$1" "{ \"$2\" }"; }
# Absent is success; anything else is a genuine failure and must surface, or a broken
# `net voff` is indistinguishable from one that had nothing to do.
set_del() {
    set_has "$1" "$2" || return 0
    ${NFT} delete element inet fw "$1" "{ \"$2\" }"
}
set_has() { ${NFT} list set inet fw "$1" 2>/dev/null | grep -q "\"$2\""; }
set_flush() { ${NFT} flush set inet fw "$1" 2>/dev/null; return 0; }
set_empty() { ! ${NFT} list set inet fw "$1" 2>/dev/null | grep -q 'elements'; }

# -- intent: what was asked for, as distinct from what is currently possible -------
# Emptiness can't answer "is it on": @host_egress is empty both for `net off` and for the
# vpn switch on with no tunnel yet, and those must behave differently -- the second has to
# start passing traffic the moment a tunnel appears, unattended. So the request is
# recorded here and reconcile() derives every set from it. Three keys: host, docker
# (permissions), vpn (a path). Lives in /run so a reboot resets to the ruleset's declared
# closed state, but a reload preserves it, since a reload is not a policy change.
intent_get() {
    local v
    v=$(sed -n "s/^$1=//p" "$INTENT" 2>/dev/null | tr -d '[:space:]')
    [[ "$v" == "1" ]] && echo 1 || echo 0
}

# Written through a temp file: a truncate-then-write could leave it empty mid-write,
# which reads as "everything off" -- safe direction, but would silently drop a live toggle.
intent_set() {
    local k="$1" v="$2" tmp
    tmp=$(mktemp "${INTENT}.XXXXXX") || return 1
    [[ -f "$INTENT" ]] && { grep -v "^${k}=" "$INTENT" >> "$tmp" 2>/dev/null || true; }
    echo "${k}=${v}" >> "$tmp"
    mv -f "$tmp" "$INTENT" || return 1
    chmod 644 "$INTENT"
    return 0
}

# -- vpn: path, not permission ----------------------------------------------------
# A tunnel is recognised by device TYPE (same axis waybar_vpn_status.sh uses), never by
# name, so no file here needs to know which provider is installed.

is_tunnel() {
    local f
    [[ -n "$1" ]] || return 1

    # tun_flags alone isn't enough: libvirt's tap devices (vnet0, vnet1) carry the same
    # file, and counting them as tunnels would exempt vm traffic from lateral_check's
    # rfc1918 drop and masquerade it -- a hole that only appears once a vm is running.
    # IFF_TUN is 0x1 (openvpn's point-to-point device), IFF_TAP is 0x2 (libvirt).
    if [[ -r "/sys/class/net/$1/tun_flags" ]]; then
        f=$(< "/sys/class/net/$1/tun_flags")
        (( f & 0x1 ))
        return $?
    fi
    grep -qs '^DEVTYPE=wireguard$' "/sys/class/net/$1/uevent"      # wireguard
}

# Every up tunnel -- used for the masquerade and rfc1918 exemption, which must cover
# split tunnels too, not just the one holding the default route.
vpn_ifaces() {
    local p n
    for p in /sys/class/net/*; do
        n=${p##*/}
        [[ "$(cat "$p/operstate" 2>/dev/null)" == "down" ]] && continue
        is_tunnel "$n" && echo "$n"
    done
}

# A handshake this recent means the peer is live -- wireguard rekeys roughly every two
# minutes, so three is live-now with room to spare.
VPN_HANDSHAKE_MAX=180

# The tunnel actually CARRYING traffic, not just present -- a merely-up tunnel must not
# take the host offline. Two methods, because one misses a real client: `route get`
# catches wg-quick and anything owning the default route, but not Mullvad, which routes
# via ip rules a plain lookup won't reflect. Falls back to a recent wireguard handshake as
# proof of a live peer when the route says nothing.
vpn_live_iface() {
    local dev now ts iface peer

    dev=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP '\bdev \K\S+' | head -1)
    if is_tunnel "$dev"; then echo "$dev"; return 0; fi

    command -v wg >/dev/null || return 1
    now=$(date +%s)
    while read -r iface peer ts; do
        [[ -n "${ts:-}" && "$ts" != 0 ]] || continue
        if (( now - ts < VPN_HANDSHAKE_MAX )); then echo "$iface"; return 0; fi
    done < <(wg show all latest-handshakes 2>/dev/null)
    return 1
}

# Live tunnel as "<iface>:<ifindex>" -- an identity, not just a name. The ifindex is the
# point: a relay change is a RECONNECT, and Mullvad's replacement device reuses the OLD
# NAME, so a name comparison can't tell "still the outgoing device, about to be torn
# down" from "the new one, up and working" -- and a handshake stays fresh for
# VPN_HANDSHAKE_MAX after the swap. The ifindex changes exactly when the device is
# actually replaced.
vpn_live_id() {
    local i idx
    i=$(vpn_live_iface) || return 1
    [[ -n "$i" ]] || return 1
    idx=$(< "/sys/class/net/$i/ifindex") 2>/dev/null || return 1
    echo "${i}:${idx}"
}

# "addr port" per line for the tunnel's own outer traffic. Read from the live tunnel
# rather than configured -- the endpoint is the one provider-specific fact here.
# VPN_ENDPOINT in vpn.conf overrides when detection fails (an unusual client, or a
# provider proxying over something odd).
vpn_endpoint_list() {
    local e
    if [[ -n "$VPN_ENDPOINT" ]]; then
        for e in $VPN_ENDPOINT; do echo "${e%:*} ${e##*:}"; done
        return 0
    fi
    # wireguard reports the peer exactly
    command -v wg >/dev/null &&
        wg show all endpoints 2>/dev/null | grep -oE '[0-9.]+:[0-9]+$' | tr ':' ' '
    # openvpn: the socket the client actually holds open
    command -v ss >/dev/null &&
        ss -tunap 2>/dev/null | grep -F 'openvpn' | awk '{print $6}' |
        grep -oE '^[0-9.]+:[0-9]+$' | tr ':' ' '
}

# Points the resolver rules at $1, in both the filter set and the dnat map. docker0 is in
# the map because compose hands containers $DNS directly -- they can't be told to follow
# the tunnel, so this rewrite does it for them.
dns_use() {
    set_flush dns_target
    ${NFT} add element inet fw dns_target "{ $1 }"
    ${NFT} flush map ip fwnat dns_rewrite 2>/dev/null
    ${NFT} add element ip fwnat dns_rewrite \
        "{ \"vmmail\" : $1, \"vmweb\" : $1, \"vmdev\" : $1, \"docker0\" : $1 }"

    # br-* deliberately excluded: devnet/hostnet have no forward-chain egress accept at
    # all now, so a rewrite here would only suggest reachability that isn't there. Their
    # containers resolve each other via docker's own embedded resolver instead.
    return 0
}

# Advisory output from reconcile -- "no tunnel yet" and friends. Every line is true at the
# instant it fires and often false a second later, because a connect passes THROUGH
# exactly the states these describe. So callers mid-transition set RECON_QUIET=1, and the
# settled pass speaks normally. Only advisory lines go through this -- a set that failed
# to populate is a real failure and always prints.
recon_note() {
    [[ "${RECON_QUIET:-0}" == "1" ]] && return 0
    local first="$1" l
    shift
    echo "[!] Firewall: ${first}" >&2
    for l in "$@"; do echo "    ${l}" >&2; done
    return 0
}

# Brings every set into line with (intent + reality). One function, called by every entry
# point, so there's a single source of truth for the ordering. Fully derived -- every set
# it owns is flushed and rebuilt from intent each time, so nothing stale can survive.
reconcile() {
    local i tun resolver addr port e
    local -a tuns=()

    # Read the kernel once: a device appearing/disappearing mid-reconcile can't then make
    # two decisions disagree -- the old code re-read live state partway through and could
    # repopulate @vpn_endpoints from a relay that had already gone.
    while read -r i; do [[ -n "$i" ]] && tuns+=( "$i" ); done < <(vpn_ifaces)

    # Both copies from one list: the filter table's and the nat table's, separate objects
    # only because sets can't cross a table boundary.
    set_flush vpn_iface
    ${NFT} flush set ip fwnat vpn_iface 2>/dev/null
    for i in "${tuns[@]}"; do
        set_add vpn_iface "$i"
        ${NFT} add element ip fwnat vpn_iface "{ \"$i\" }"
    done

    # Build the list first, replace only if non-empty: this set is the only thing
    # permitting encapsulation out once conntrack is flushed, and `wg show` reports
    # nothing mid re-establish. A stale endpoint costs one permitted udp destination; an
    # empty set costs the whole connection.
    local -a eps=()
    while read -r addr port; do
        [[ -n "$addr" && -n "$port" ]] && eps+=( "$addr . $port" )
    done < <(vpn_endpoint_list)

    # "Is there a tunnel at all" is answered from the snapshot taken above, not asked
    # again -- fixes an observed bug where a disconnect mid-check left the set repopulated
    # from a relay that no longer existed. This entry feeds an accept ABOVE both toggles,
    # so only a reload can close it if it goes stale -- the one direction this must never
    # drift in.
    if [[ "$(intent_get vpn)" != "1" ]]; then
        # Off means treat the vpn as though it doesn't exist, holes included -- else a
        # client could still connect and have its traffic silently dropped, since the path
        # sets hold the wan. Better it fails at connect time, where the client says so.
        set_flush vpn_endpoints
    elif (( ${#tuns[@]} == 0 )); then
        # No tunnel device at all, so nothing to keep alive.
        set_flush vpn_endpoints
    elif (( ${#eps[@]} )); then
        set_flush vpn_endpoints
        for e in "${eps[@]}"; do
            ${NFT} add element inet fw vpn_endpoints "{ $e }"
        done
    fi
    # Deliberately no else: a tunnel exists but no endpoint could be read. That's either
    # the re-establish moment above, or a client running wireguard in USERSPACE
    # (gotatun-style) whose plain tun device `wg show` can't see. Keeping the last known
    # endpoint is right for the former; the latter is a known blind spot -- set
    # VPN_ENDPOINT in vpn.conf if a client ever lands there permanently.

    # The client's in-tunnel probe. Populated only while the switch is on and only from
    # VPN_CONTROL -- absent config means an empty set, a no-op for a client with no check.
    set_flush vpn_control
    if [[ "$(intent_get vpn)" == "1" && -n "${VPN_CONTROL:-}" ]]; then
        for e in $VPN_CONTROL; do
            [[ "$e" == *:* ]] || { echo "[!] Firewall: VPN_CONTROL entry '${e}' is not addr:port, ignored" >&2; continue; }
            ${NFT} add element inet fw vpn_control "{ ${e%:*} . ${e##*:} }" ||
                echo "[!] Firewall: could not add ${e} to vpn_control" >&2
        done
    fi
    # A client that needs this probe and was never told the address will connect, fail its
    # own readiness check and tear the tunnel down -- cheap to warn here, expensive to
    # trace from the far end.
    if [[ "$(intent_get vpn)" == "1" && -z "${VPN_CONTROL:-}" && ${#tuns[@]} -gt 0 ]]; then
        recon_note "VPN_CONTROL is unset in ${VPN_CONFIG}. If the client probes an" \
                   "in-tunnel address to decide it is connected (mullvad: 10.64.0.1:1337)," \
                   "that probe is being dropped. Set it with 'net vpn'."
    fi

    if tun=$(vpn_live_iface) && [[ -n "$tun" ]]; then
        # No VPN_DNS: queries would target the lan resolver while the tunnel owns the
        # default route -- unroutable, so dns just stops. Say so rather than let it look
        # like the tunnel broke.
        if [[ -z "$VPN_DNS" ]]; then
            recon_note "tunnel ${tun} is up but VPN_DNS is unset in ${VPN_CONFIG};" \
                       "keeping the lan resolver, which the tunnel cannot reach."
            resolver="$DNS_SERVER"
        else
            resolver="$VPN_DNS"
            # A stale VPN_DNS doesn't degrade, it kills dns dead for what sits behind the
            # host (which keeps working, via resolv.conf) -- and providers move this
            # address when you enable their own filtering, so it's not a rare case.
            if command -v resolvectl >/dev/null &&
               ! resolvectl status 2>/dev/null | grep -qF "$VPN_DNS"; then
                recon_note "VPN_DNS=${VPN_DNS} is not a resolver this system is" \
                           "actually using -- container and vm dns will fail. Check:" \
                           "resolvectl status | grep -iA2 'current dns'"
            fi
        fi
    else
        resolver="$DNS_SERVER"
    fi
    dns_use "$resolver"

    # -- egress: one path list, three permissions ----------------------------------
    # WHICH ROUTE is the vpn switch's answer, same for everybody; WHO MAY USE IT is each
    # class's own switch. The vpn switch never grants egress to a class whose own switch
    # is off -- the bug this replaced gave the vpn its own egress set, so `net vpon` handed
    # the host a way out that `net off` had withdrawn, via dockerd (a host process) pulling
    # images through it.
    #
    # Tunnel devices come from EXISTENCE, not liveness: wireguard only handshakes when it
    # has data to send, so gating on liveness would wait for a state this rule itself
    # prevents (Mullvad reports that as stuck at "blocked").
    local -a paths=()
    if [[ "$(intent_get vpn)" == "1" ]]; then
        # No fallback to the wan when no tunnel exists -- that would be exactly the
        # untunnelled leak the switch exists to prevent. A killswitch commitment, not a
        # preference.
        paths=( "${tuns[@]}" )
    else
        paths=( "$WAN_IFACE" )
    fi

    local s
    for s in host_egress docker_egress; do
        set_flush "$s"
    done
    set_flush vm_paths
    set_flush host_lan

    # host_lan follows the host's PERMISSION but never the vpn PATH -- can't be folded into
    # host_egress, whose job is to hold whichever path the switch picked (the tunnel, once
    # on), which would cut the host off from its own router every time the vpn came up.
    if [[ "$(intent_get host)" == "1" ]]; then
        set_add host_lan "$WAN_IFACE" ||
            echo "[!] Firewall: could not add ${WAN_IFACE} to host_lan" >&2
    fi

    # vm_paths has no permission gate of its own -- a bridge's permission is its
    # @vm_egress membership -- so this only ever answers "by which route".
    for i in "${paths[@]}"; do
        set_add vm_paths "$i" || echo "[!] Firewall: could not add ${i} to vm_paths" >&2
    done
    if [[ "$(intent_get host)" == "1" ]]; then
        for i in "${paths[@]}"; do
            set_add host_egress "$i" || echo "[!] Firewall: could not add ${i} to host_egress" >&2
        done
    fi
    if [[ "$(intent_get docker)" == "1" ]]; then
        for i in "${paths[@]}"; do
            set_add docker_egress "$i" || echo "[!] Firewall: could not add ${i} to docker_egress" >&2
        done
    fi

    # Advisory for "switch on, nothing carrying it" -- silenced mid-connect, since `net
    # vpon` passes through precisely this state on its way to a working tunnel.
    if [[ "$(intent_get vpn)" == "1" && ${#tuns[@]} -eq 0 ]]; then
        recon_note "the vpn switch is on and no tunnel is up, so nothing can" \
                   "egress -- by design, an untunnelled path would defeat the switch." \
                   "Connect the vpn, or 'net vpoff' to go back out through the wan."
    fi
    return 0
}

# Display cache for waybar/tmux, which run unprivileged; `status` reads the sets
# directly. In /run so a reboot can't leave it stale. Written via temp file + rename, same
# reasoning as intent_set -- waybar_vpn_status.sh *sources* this file, so a reader
# catching a half-written truncate could source a broken assignment. The settle loop
# rewrites this once a second for 20s during a connect, so this window opens often.
write_state() {
    local i w t tmp
    tmp=$(mktemp "${STATE}.XXXXXX") || return 1
    {
        # `host` keeps its old meaning so the bar scripts didn't need to change; `vpn` (the
        # path switch) is published alongside it rather than merged in -- merging them
        # once lit the host icon for a host that was still cut off.
        w=$(intent_get host); t=$(intent_get vpn)
        echo "host=${w}"
        echo "vpn=${t}"
        # Whether the switch is actually being honoured by a live tunnel.
        if [[ "$t" == "1" ]] && ! set_empty vm_paths; then echo "vpn_ready=1"; else echo "vpn_ready=0"; fi
        set_empty docker_egress && echo "docker=0" || echo "docker=1"
        for i in vmmail vmweb vmdev; do
            set_has vm_egress "$i" && echo "${i}=1" || echo "${i}=0"
            set_has vm_update "$i" && echo "${i}_update=1" || echo "${i}_update=0"
        done
        # Which way traffic is currently leaving, for the bar.
        if i=$(vpn_live_iface) && [[ -n "$i" ]]; then
            echo "path=${i}"; echo "tunnelled=1"
        else
            echo "path=${WAN_IFACE}"; echo "tunnelled=0"
        fi
    } > "$tmp"
    chmod 644 "$tmp"
    mv -f "$tmp" "$STATE" || { rm -f "$tmp"; return 1; }
    return 0
}

# Cut live flows too, so a toggle is not merely advisory against something already
# connected. Skipped when conntrack-tools is absent.
ct_flush() { command -v conntrack >/dev/null && conntrack -D "$@" >/dev/null 2>&1; return 0; }

# Cuts the host's live flows on every path at once -- over-listing an unused address is
# free, under-listing leaves a download running after `net off`.
#
# LAN ssh is NOT exempted, even though it's ungated in the ruleset: conntrack -D has no
# negation, so excepting one flow means deleting every other one individually -- a parser
# whose failure mode is silent under-deletion. A blanket delete only fails safe.
#
# The session survives regardless on a default kernel: deleting the entry doesn't reset
# the socket, and the client's next packet is picked up as `ct state new` by
# nf_conntrack_tcp_loose (on by default), which the ungated rule matches. With
# tcp_loose=0 you reconnect instead -- which now works, where `net off` used to deny that too.
ct_flush_host() {
    local a
    while read -r a; do
        [[ -n "$a" ]] && ct_flush -s "$a"
    done < <(host_addrs)
    return 0
}

# Every source address the host can currently emit from. More than one matters: a
# tunnelled connection has TWO conntrack entries (the inner flow, sourced from the tunnel
# address, and the outer encapsulation, sourced from the wan address), and which one a
# single lookup returns depends on the client -- wg-quick owns the default route so
# `route get` answers with the tunnel, leaving direct wan flows alive; Mullvad routes by
# ip rules so the same lookup answers with the wan, leaving tunnelled flows alive either
# way. So: enumerate rather than deduce -- the wan iface, every live tunnel, a route-lookup
# backstop for a stale WAN_IFACE, then HOST_IP last for when there's no route at all.
host_addrs() {
    local i
    {
        iface_addrs "$WAN_IFACE"
        while read -r i; do
            [[ -n "$i" ]] && iface_addrs "$i"
        done < <(vpn_ifaces)
        ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+'
        echo "$HOST_IP"
    } | grep -v '^$' | sort -u
}

iface_addrs() {
    [[ -n "$1" ]] || return 0
    ip -4 -o addr show dev "$1" 2>/dev/null | awk '{split($4,a,"/"); print a[1]}'
}

# The inner flows, for `net vpoff` -- called alongside ct_flush_host rather than instead
# of it, since switching the path away from the tunnel must retire connections on both
# sides.
ct_flush_tun() {
    local i a
    while read -r i; do
        [[ -n "$i" ]] || continue
        while read -r a; do
            [[ -n "$a" ]] && ct_flush -s "$a"
        done < <(iface_addrs "$i")
    done < <(vpn_ifaces)
    return 0
}

vm_iface() {
    case "$1" in
        mail) echo vmmail ;;
        web)  echo vmweb  ;;
        dev)  echo vmdev  ;;
        *)    die "unknown vm network '$1' (expected: mail, web, dev)" ;;
    esac
}
# $1 = bridge iface, $2 = column (2 = subnet, 3 = router address)
vm_field() {
    local want="$1" col="$2" e name net router
    for e in "${VM_NETS[@]}"; do
        read -r name net router <<<"$e"
        if [[ "$name" == "$want" ]]; then
            [[ "$col" == 2 ]] && echo "$net" || echo "$router"
            return 0
        fi
    done
    return 1
}
vm_subnet() { vm_field "$1" 2; }

# -- temporary update grant --------------------------------------------------------
# `net vupdate <n>`: http/https for a bridge whose role ports don't include them, so the
# vm can reach its package mirrors and nothing more. Safe to hand out casually: the grant
# lives only in a set, never in $RULES, so a reload or reboot revokes it, and it carries
# its own timeout, so it self-revokes if forgotten. It grants ports, not reachability --
# @vm_egress, lateral_check and the wan/tunnel requirement all still apply above it.
vm_update_grant() {
    local iface="$1" mins="$2"
    [[ "$mins" =~ ^[0-9]+$ && "$mins" -gt 0 ]] ||
        die "duration must be a positive whole number of minutes, got '$mins'"
    # Re-granting refreshes rather than stacks: nft replaces the element and its timeout.
    ${NFT} add element inet fw vm_update "{ \"$iface\" timeout ${mins}m }" || return 1
    # The ports are open but the bridge has no egress at all, so nothing will work and the
    # reason is one layer down. Cheaper to say now than to debug as "vupdate is broken".
    set_has vm_egress "$iface" ||
        echo "[!] Firewall: ${iface} has http/https but its egress is off -- 'net von' first." >&2
    return 0
}

# Cuts the two granted ports and nothing else: `net voff` flushes the whole subnet
# ("this vm is off"); this means "the update window is over", and tearing down e.g. the
# mail vm's live imap sessions to end it would be a surprise, not a tightening.
vm_update_revoke() {
    local iface="$1" net
    set_del vm_update "$iface" || return 1
    net=$(vm_subnet "$iface") || return 0
    ct_flush -s "$net" -p tcp --dport 80
    ct_flush -s "$net" -p tcp --dport 443
    return 0
}

# Time left on a grant, empty when there is none. nft prints an element of a timeout set
# as `"vmmail" timeout 30m expires 29m56s854ms`; trailing ms is stripped, but only when a
# larger unit survives, so the last second before expiry isn't left blank.
vm_update_left() {
    ${NFT} list set inet fw vm_update 2>/dev/null |
        grep -oP "\"$1\"[^,}]*expires \K[^ ,}]+" | head -1 |
        sed -E 's/([0-9]+[dhms])[0-9]+ms$/\1/'
}

do_status() {
    local h d
    [[ "$(intent_get host)" == "1" ]] && h="ON" || h="OFF"
    [[ "$(intent_get docker)" == "1" ]] && d="ON" || d="OFF"
    echo "host   ${h}"
    echo "docker ${d}"
    # One word per state so `net` can parse with `read name val extra`. "pending" is the
    # committed-but-unconnected state -- switch on, no tunnel, so nothing egresses despite
    # what the two rows above say -- worth its own label rather than folding into plain ON.
    if [[ "$(intent_get vpn)" != "1" ]]; then
        echo "vpn    OFF"
    elif set_empty vm_paths; then
        echo "vpn    ON pending"
    else
        echo "vpn    ON"
    fi
    local i left
    for i in vmmail vmweb vmdev; do
        set_has vm_egress "$i" && echo "${i} ON" || echo "${i} OFF"
    done
    # Only when one is live -- a permanent "update OFF" row would be noise on every status.
    for i in vmmail vmweb vmdev; do
        left=$(vm_update_left "$i")
        [[ -n "$left" ]] && echo "update ${i} ${left}"
    done
    if i=$(vpn_live_iface) && [[ -n "$i" ]]; then
        echo "path ${i} tunnelled"
    else
        echo "path ${WAN_IFACE} direct"
    fi
}

check_root
case "$1" in
    # deny_all before load_config: a bad /etc/network.conf would otherwise die here with
    # no tables loaded at all, i.e. nothing filtering. $STATE is cleared for the same
    # window, so the bar can't claim "host ON" while deny-all is blocking everything.
    start|restart) lock_take
                   deny_all || die "could not install the deny-all fallback"
                   rm -f "$STATE"
                   # reconcile before write_state: a fresh ruleset has empty vpn sets and
                   # no resolver until it runs. Also restores toggles from $INTENT, so a
                   # reload no longer silently takes the host offline -- a reboot still
                   # clears /run and comes up closed, since only a reload is preserved.
                   load_config; do_start; reconcile; write_state ;;
    check)         load_config; do_check ;;
    render)        load_config; render ;;
    flush)         lock_take; do_flush; rm -f "$STATE" ;;
    status)        load_config; do_status ;;

    # Reconciles every set with (intent + reality): a tunnel appearing starts carrying
    # egress if it was granted, a tunnel going away stops. Idempotent, callable from
    # anywhere.
    vpn-sync)      lock_take; load_config; reconcile; write_state ;;

    # The udev entry point. A tunnel device exists a moment before it owns the default
    # route, so syncing on the device event alone would wrongly read "no tunnel" this
    # early -- expected, not news, so only the final settled pass is allowed to report.
    vpn-sync-settle)
        # Single-flight: udev passes --skip-if-busy and leaves if a loop is already
        # running; `net vpon` waits, since it needs the answer.
        settle_take "${2:-}" || exit 0
        lock_take; load_config; RECON_QUIET=1 reconcile; write_state
        # Lock dropped for the wait, so a `net off` typed mid-connect isn't blocked for
        # the full 20s.
        lock_drop
        # Reconciles EACH pass, not just polls liveness. The first connect after `net
        # vpoff` used to fail every time: `net vpon`'s initial reconcile (no device yet)
        # flushes @vpn_endpoints, and a client that has created its device but not yet
        # published its peer reports no endpoint -- so the "keep last known endpoint"
        # branch kept the empty set it was just flushed to, and the handshake was dropped
        # for the whole wait. Re-reconciling each pass closes the endpoint hole the moment
        # the client publishes its peer. The resolver needs the settle too: vpn_live_iface
        # decides vm/container dns, and that's only correct once the tunnel actually
        # carries traffic.
        #
        # BREAKS ON A STABLE IDENTITY (same ifindex twice), not on liveness. A relay
        # change is a reconnect where Mullvad's replacement device reuses the OLD NAME, so
        # a liveness-only check reports "live" against the outgoing device -- torn down a
        # second later, which used to make `net vprelay` report on a tunnel that no longer
        # existed. Requiring the same ifindex on two consecutive samples costs one second
        # on a normal connect and rules that out: the replacement gets a new ifindex even
        # when it reuses the name.
        prev=""
        for ((i = 0; i < 20; i++)); do
            sleep 1
            lock_take; RECON_QUIET=1 reconcile; write_state; lock_drop
            cur=$(vpn_live_id)
            [[ -n "$cur" && "$cur" == "$prev" ]] && break
            prev="$cur"
        done
        # One more beat before the pass allowed to complain: a tunnel handshakes before
        # resolved installs its resolver, so judging VPN_DNS right at break-out would
        # report a mismatch that fixes itself a moment later.
        sleep 1
        lock_take; reconcile; write_state
        # Exit 3, not 1, for "settled, no tunnel" -- an outcome the caller treats
        # differently from a malfunction. udev logs this as a failed transient unit, the
        # only place it's recorded.
        [[ -n "$(vpn_live_id)" ]] || exit 3
        exit 0 ;;

    # Records only what was asked, then lets reconcile derive every set -- verbs no longer
    # touch sets directly, closing the bug where a toggle and vpn-sync disagreed about
    # which interface belonged where. See reconcile()'s egress-model comment for the
    # who/how split each verb respects.
    enable-net)         lock_take; load_config; intent_set host 1; reconcile; write_state ;;
    disable-net)        lock_take; load_config; intent_set host 0; reconcile
                        ct_flush_host; write_state ;;

    # Both directions flush the host's connections: leaving a flow on the old path would
    # be exactly the leak this switch exists to stop. Quiet on enable, since turning on is
    # the START of a connect -- the settle's final pass reports if still untunnelled once
    # things settle.
    enable-vpn-net)     lock_take; load_config; intent_set vpn 1; RECON_QUIET=1 reconcile
                        ct_flush_host; write_state ;;
    disable-vpn-net)    lock_take; load_config; intent_set vpn 0; reconcile
                        ct_flush_host; ct_flush_tun; write_state ;;

    enable-docker-net)  lock_take; load_config; intent_set docker 1; reconcile; write_state ;;
    disable-docker-net) lock_take; load_config; intent_set docker 0; reconcile
                        ct_flush -s 172.16.0.0/12; write_state ;;

    enable-vm-net)  lock_take; load_config; iface=$(vm_iface "$2") || exit 1; set_add vm_egress "$iface"; write_state ;;
    disable-vm-net) lock_take; load_config; iface=$(vm_iface "$2") || exit 1
                    set_del vm_egress "$iface"; ct_flush -s "$(vm_subnet "$iface")"; write_state ;;

    # A grant with an expiry rather than a toggle, so there is no "on" state to forget
    # about. $3 is minutes; absent means VM_UPDATE_MINUTES.
    enable-vm-update)  lock_take; load_config; iface=$(vm_iface "$2") || exit 1
                       vm_update_grant "$iface" "${3:-$VM_UPDATE_MINUTES}" || exit 1
                       write_state ;;
    disable-vm-update) lock_take; load_config; iface=$(vm_iface "$2") || exit 1
                       vm_update_revoke "$iface" || exit 1; write_state ;;

    *)
        echo "Usage: $0 start|restart|check|render|flush|status|vpn-sync" >&2
        echo "       $0 vpn-sync-settle [--skip-if-busy]   (exit 3 = settled, no tunnel)" >&2
        echo "       $0 enable-net|disable-net|enable-vpn-net|disable-vpn-net" >&2
        echo "       $0 enable-docker-net|disable-docker-net" >&2
        echo "       $0 enable-vm-net|disable-vm-net <mail|web|dev>" >&2
        echo "       $0 enable-vm-update <mail|web|dev> [minutes]" >&2
        echo "       $0 disable-vm-update <mail|web|dev>" >&2
        exit 1
        ;;
esac
