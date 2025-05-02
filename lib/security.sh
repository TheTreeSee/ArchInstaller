#!/bin/bash

### FUNCTION: Configure Security ###
configure_security() {
    arch-chroot /mnt /bin/bash <<EOF
    # Configure SSH
    pacman -S --noconfirm openssh
    systemctl enable sshd

    # Basic firewall setup with firewalld
    pacman -S --noconfirm firewalld
    systemctl enable firewalld
    systemctl start firewalld

    # Set default zone to public and deny all incoming except SSH and Minecraft
    firewall-cmd --permanent --set-default-zone=public
    firewall-cmd --permanent --zone=public --add-service=ssh
    firewall-cmd --permanent --zone=public --add-port=25565/tcp
    firewall-cmd --permanent --zone=public --set-target=DROP
    firewall-cmd --reload

    # Harden system settings
    echo "kernel.kptr_restrict=2" >> /etc/sysctl.d/51-kptr-restrict.conf
    echo "kernel.dmesg_restrict=1" >> /etc/sysctl.d/51-dmesg-restrict.conf
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.d/51-tcp-hardening.conf
EOF
}