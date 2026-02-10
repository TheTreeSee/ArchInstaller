#!/bin/bash

_sec_prefix="[security]"

# Harden system settings
harden_system() {
    echo "[INFO] ${_sec_prefix} Applying basic kernel and network hardening..."
    echo "kernel.kptr_restrict=2" >> /etc/sysctl.d/51-kptr-restrict.conf
    echo "kernel.dmesg_restrict=1" >> /etc/sysctl.d/51-dmesg-restrict.conf
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.d/51-tcp-hardening.conf
    echo "[OK] ${_sec_prefix} Sysctl hardening configuration written."
}

if [ "$#" -gt 0 ]; then
    for fn in "$@"; do
        echo "[INFO] ${_sec_prefix} Running function '$fn'..."
        "$fn"
    done
else
    # Default flow
    harden_system
fi