#!/bin/bash

setup_network() {
    step "Network configuration"
    info "Creating basic DHCP systemd-networkd profiles for all non-loopback interfaces..."

    # Enable systemd-networkd and systemd-resolved (left commented for now)
    # arch-chroot /mnt systemctl enable systemd-networkd
    # arch-chroot /mnt systemctl enable systemd-resolved

    # Symlink resolv.conf for systemd-resolved
    # arch-chroot /mnt ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    # Detect all ethernet interfaces (excluding loopback)
    interfaces=$(ls /sys/class/net | grep -v lo)

    for iface in $interfaces; do
        info "Configuring DHCP for interface $iface..."
        # Create a .network file for each interface
        cat <<EOF > /mnt/etc/systemd/network/20-$iface.network
[Match]
Name=$iface

[Network]
DHCP=yes
EOF
    done

    success "Network configuration files created."
}


# # [ "$SERVER_MODE" = false ] && systemctl enable iwd

# # Configure SSH
# pacman -S --noconfirm openssh
# systemctl enable sshd

# # Basic firewall setup with firewalld
# pacman -S --noconfirm firewalld
# systemctl enable firewalld
# systemctl start firewalld

# # Set default zone to public and deny all incoming except SSH and Minecraft
# firewall-cmd --permanent --set-default-zone=public
# firewall-cmd --permanent --zone=public --add-service=ssh
# firewall-cmd --permanent --zone=public --add-port=25565/tcp
# firewall-cmd --permanent --zone=public --set-target=DROP
# firewall-cmd --reload