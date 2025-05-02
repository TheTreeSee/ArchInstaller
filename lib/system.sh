#!/bin/bash

### FUNCTION: Install Base System ###
install_base_system() {
    echo "Installing base system..."

    # Install microcode based on CPU vendor
    local microcode=""
    if [ "$CPU_VENDOR" = "intel" ]; then
        microcode="intel-ucode"
    elif [ "$CPU_VENDOR" = "amd" ]; then
        microcode="amd-ucode"
    fi

    # Install base packages
    pacstrap /mnt base "$KERNEL" linux-firmware "$microcode"
    echo "Base system installation complete."
}

### FUNCTION: Install Essential Packages ###
install_essentials() {
    echo "Installing essential packages..."

    # Install GRUB and necessary tools
    pacstrap /mnt grub efibootmgr base-devel vim man-db man-pages git

    # Install network tools based on server mode
    if [ "$SERVER_MODE" = true ]; then
        pacstrap /mnt systemd-networkd systemd-resolved
    else
        pacstrap /mnt iwd systemd-networkd systemd-resolved os-prober xdg-user-dirs
    fi

    echo "Essential packages installed."
}

### FUNCTION: Generate fstab ###
generate_fstab() {
    echo "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    echo "fstab generation complete."
}

### FUNCTION: Set Keyboard Layout ###
set_keymap() {
    echo "Setting keyboard layout to $KEYMAP..."
    case "$KEYMAP" in
        colemak)
            echo "KEYMAP=colemak" > /mnt/etc/vconsole.conf
            ;;
        be|fr|azerty)
            # Belgian AZERTY (be-latin1 is the common console keymap for Belgian/French AZERTY)
            echo "KEYMAP=be-latin1" > /mnt/etc/vconsole.conf
            ;;
        us|qwerty)
            echo "KEYMAP=us" > /mnt/etc/vconsole.conf
            ;;
        *)
            echo "Invalid keymap selected, defaulting to US QWERTY."
            echo "KEYMAP=us" > /mnt/etc/vconsole.conf
            ;;
    esac
}


### FUNCTION: Configure System Inside Chroot ###
configure_system() {
    echo "Configuring system inside chroot..."
    arch-chroot /mnt /bin/bash <<EOF

    # Set hostname
    echo "$HOSTNAME" > /etc/hostname

    # Set timezone
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc

    # Configure locale
    echo "$LOCALE.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=$LOCALE" > /etc/locale.conf

    # TODO MOVE TO NETWORK
    # Enable network services
    # systemctl enable systemd-networkd
    # systemctl enable systemd-resolved
    # [ "$SERVER_MODE" = false ] && systemctl enable iwd

    # Install and configure GRUB
    grub-install --target=x87_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

    # Set root password
    if [ -z "$PASSWORD" ] && [ "$UNATTENDED" = false ]; then
        echo "Set root password:"
        passwd
    else
        echo "root:$PASSWORD" | chpasswd
    fi

    # Create user and grant sudo privileges
    useradd -m -G wheel "$USERNAME"
    if [ -z "$PASSWORD" ] && [ "$UNATTENDED" = false ]; then
        echo "Set password for $USERNAME:"
        passwd "$USERNAME"
    else
        echo "$USERNAME:$PASSWORD" | chpasswd
    fi

    # Configure secure sudo settings
    cat > /etc/sudoers.d/00-wheel <<END
    Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    Defaults        env_reset
    Defaults        mail_badpass
    Defaults        passwd_timeout=0
    Defaults        timestamp_timeout=5
    Defaults        badpass_message="Password is wrong, please try again"
    Defaults        editor=/usr/bin/vim
    Defaults        insults

    # Allow members of group wheel to execute any command after authentication
    %wheel ALL=(ALL:ALL) ALL
    END

    chmod 440 /etc/sudoers.d/00-wheel

    echo "System configuration complete."

    echo "Downloading postinstall."
    curl -o /root/postinstall.sh https://raw.githubusercontent.com/thetreesee/archinstaller/main/postinstall.sh
    chmod +x /root/postinstall.sh

    # Create a systemd service to run it at first boot
    cat <<EOL > /etc/systemd/system/postinstall.service
    [Unit]
    Description=Run postinstall script once
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=oneshot
    ExecStart=/root/postinstall.sh
    RemainAfterExit=no

    [Install]
    WantedBy=multi-user.target
    EOL

    # Enable the one-shot service
    systemctl enable postinstall.service

    exit
EOF
}

### FUNCTION: Final Steps Before Reboot ###
finalize_installation() {
    echo "Finalizing installation..."
    echo "Unmounting partitions..."
    umount -R /mnt

    echo "Installation summary:"
    echo "- Hostname: $HOSTNAME"
    echo "- Username: $USERNAME"
    echo "- Keyboard Layout: $KEYMAP"
    echo "- Server Mode: $SERVER_MODE"

    # if [ "$UNATTENDED" = true ]; then
    #     echo "Unattended mode enabled. Rebooting..."
    #     reboot
    # else
        read -p "Installation complete! Press Enter to reboot or Ctrl+C to stay in the live environment..."
        reboot
    # fi
}