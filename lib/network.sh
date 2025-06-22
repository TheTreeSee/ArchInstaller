#!/bin/bash

setup_network() {
    # Enable systemd-networkd and systemd-resolved
    arch-chroot /mnt systemctl enable systemd-networkd
    arch-chroot /mnt systemctl enable systemd-resolved

    # Symlink resolv.conf for systemd-resolved
    arch-chroot /mnt ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    # Detect all ethernet interfaces (excluding loopback)
    interfaces=$(ls /sys/class/net | grep -v lo)

    for iface in $interfaces; do
        # Create a .network file for each interface
        cat <<EOF > /mnt/etc/systemd/network/20-$iface.network
[Match]
Name=$iface

[Network]
DHCP=yes
EOF
    done
}


# todo: MOVE TO NETWORK
# Enable network services
# systemctl enable systemd-networkd
# systemctl enable systemd-resolved
# [ "$SERVER_MODE" = false ] && systemctl enable iwd