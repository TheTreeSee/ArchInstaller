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