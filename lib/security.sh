#!/bin/bash

### FUNCTION: Configure Security ###
configure_security() {
    arch-chroot /mnt /bin/bash <<EOF
    # Configure SSH
    pacman -S --noconfirm openssh
    systemctl enable sshd

    # Basic firewall setup
    pacman -S --noconfirm ufw
    systemctl enable ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw enable

    # Harden system settings
    echo "kernel.kptr_restrict=2" >> /etc/sysctl.d/51-kptr-restrict.conf
    echo "kernel.dmesg_restrict=1" >> /etc/sysctl.d/51-dmesg-restrict.conf
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.d/51-tcp-hardening.conf
EOF
}