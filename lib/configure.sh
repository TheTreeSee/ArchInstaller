#!/bin/bash

# Set hostname
set_hostname() {
    echo "$HOSTNAME" > /etc/hostname
}

# Set timezone
set_timezone() {
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
}

# Configure locale
configure_locale() {
    echo "$LOCALE.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=$LOCALE" > /etc/locale.conf
}

# Install GRUB
install_grub() {
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
}

# Set root password
set_password() {
    if [ -z "$PASSWORD" ] && [ "$UNATTENDED" = false ]; then
        echo "Set root password:"
        passwd
    else
        echo "root:$PASSWORD" | chpasswd
    fi
}

# Create user and add to wheel
user_add() {
    useradd -m -G wheel "$USERNAME"
    if [ -z "$PASSWORD" ] && [ "$UNATTENDED" = false ]; then
        echo "Set password for $USERNAME:"
        passwd "$USERNAME"
    else
        echo "$USERNAME:$PASSWORD" | chpasswd
    fi
}

# Configure sudo
# todo fix 00-wheel
configure_sudo() {
    cat /tmp/archinstaller/assets/00-wheel > /etc/sudoers.d/00-wheel
    chmod 440 /etc/sudoers.d/00-wheel
}

# todo: fix postinstall
# curl -o /root/postinstall.sh https://raw.githubusercontent.com/thetreesee/archinstaller/main/postinstall.sh
# chmod +x /root/postinstall.sh

# # Create a systemd service to run it at first boot
# cat ../assets/postinstall.service > /etc/systemd/system/postinstall.service

# # Enable the one-shot service
# systemctl enable postinstall.service

if [ "$#" -gt 0 ]; then
    for fn in "$@"; do
        "$fn"
    done
else
    # Default flow
    set_hostname
    set_timezone
    configure_locale
    install_grub
    set_password
    user_add
    configure_sudo
fi

# Run default flow:
# arch-chroot /mnt /bin/bash < configure.sh

# Run one or more functions:
# arch-chroot /mnt /bin/bash -s function1 function2 < configure.sh