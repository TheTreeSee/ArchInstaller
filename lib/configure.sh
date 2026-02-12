#!/bin/bash

_log_prefix="[chroot]"

# Set hostname
set_hostname() {
    echo "[INFO] ${_log_prefix} Setting hostname to '$HOSTNAME'..."
    echo "$HOSTNAME" > /etc/hostname
}

# Set timezone
set_timezone() {
    echo "[INFO] ${_log_prefix} Setting timezone to '$TIMEZONE'..."
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
}

enable_services() {
    echo "[INFO] ${_log_prefix} Enabling services..."
    systemctl enable systemd-timesyncd
    systemctl enable systemd-networkd
    systemctl enable systemd-resolved
}

# Configure locale
configure_locale() {
    echo "[INFO] ${_log_prefix} Configuring locale '$LOCALE'..."
    echo "$LOCALE.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=$LOCALE" > /etc/locale.conf
}

# Install GRUB
install_grub() {
    echo "[INFO] ${_log_prefix} Installing GRUB bootloader..."
    # Sanity: /boot must be mounted and contain a kernel.
    # If it's not mounted yet, try to mount it automatically using /etc/fstab.
    if ! mountpoint -q /boot; then
        echo "[WARN]  ${_log_prefix} /boot is not a mountpoint inside chroot; attempting to mount it..."

        # Prefer fstab-based mounting
        if grep -qE '^[^#]+\s+/boot\s+' /etc/fstab 2>/dev/null; then
            if ! mount /boot; then
                echo "[ERROR] ${_log_prefix} Failed to mount /boot using /etc/fstab. Please check your fstab entry for /boot."
                exit 1
            fi
        else
            echo "[ERROR] ${_log_prefix} No /boot entry found in /etc/fstab; cannot mount ESP automatically."
            echo "        ${_log_prefix} Please mount your EFI system partition at /boot and re-run configure.sh."
            exit 1
        fi
    fi

    if ! ls /boot/vmlinuz-* >/dev/null 2>&1; then
        echo "[ERROR] ${_log_prefix} No kernel found in /boot (no /boot/vmlinuz-*)."
        echo "        ${_log_prefix} This usually means the ESP was mounted after pacstrap, hiding the kernel files."
        echo "        ${_log_prefix} Try reinstalling kernel: pacman -S linux && mkinitcpio -P"
        exit 1
    fi

    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "[OK] ${_log_prefix} GRUB installation complete."
}


# Set root password
set_password() {
    if [ -z "$PASSWORD" ] && [ "$UNATTENDED" = false ]; then
        echo "[INFO] ${_log_prefix} Set root password:"
        passwd
    else
        echo "[INFO] ${_log_prefix} Setting root password from configuration..."
        echo "root:$PASSWORD" | chpasswd
    fi
}

# Create user and add to wheel
user_add() {
    echo "[INFO] ${_log_prefix} Creating user '$USERNAME' and adding to wheel group..."
    useradd -m -G wheel "$USERNAME"
    if [ -z "$PASSWORD" ] && [ "$UNATTENDED" = false ]; then
        echo "[INFO] ${_log_prefix} Set password for $USERNAME:"
        passwd "$USERNAME"
    else
        echo "[INFO] ${_log_prefix} Setting password for $USERNAME from configuration..."
        echo "$USERNAME:$PASSWORD" | chpasswd
    fi
}

# Configure sudo
configure_sudo() {
    echo "[INFO] ${_log_prefix} Securing sudoers file /etc/sudoers.d/00-wheel..."
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
    echo "[INFO] ${_log_prefix} Running Configure.sh"
    # Default flow
    set_hostname
    set_timezone
    enable_services
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