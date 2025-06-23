#!/bin/bash

# Harden system settings
harden_system() {
    echo "kernel.kptr_restrict=2" >> /etc/sysctl.d/51-kptr-restrict.conf
    echo "kernel.dmesg_restrict=1" >> /etc/sysctl.d/51-dmesg-restrict.conf
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.d/51-tcp-hardening.conf
}

if [ "$#" -gt 0 ]; then
    for fn in "$@"; do
        "$fn"
    done
else
    # Default flow
    harden_system
fi