#!/bin/bash

detect_cpu_vendor() {
  local vendor
  vendor=$(grep -m 1 'vendor_id' /proc/cpuinfo)

  if echo "$vendor" | grep -qi 'intel'; then
    echo "intel-ucode"
  elif echo "$vendor" | grep -qi 'amd'; then
    echo "amd-ucode"
  else
    echo "unknown"
  fi
}

### FUNCTION: Install Base System ###
install_base_system() {
    echo "Installing base system..."

    # Install microcode based on CPU vendor
    local microcode=""
    if [ "$CPU_VENDOR" = "auto" ]; then
        CPU_VENDOR=$(detect_cpu_vendor)
        echo "Detected CPU vendor: $CPU_VENDOR"
        if [ "$CPU_VENDOR" = "unknown" ]; then
            echo "Error: Unsupported CPU vendor detected. Please specify microcode manually."
            safe_read microcode "Enter microcode package (intel-ucode or amd-ucode or some other): "
        fi
    elif [ "$CPU_VENDOR" = "intel" ]; then
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
    pacstrap /mnt systemd-networkd systemd-resolved grub efibootmgr base-devel neovim man-db man-pages git

    # Install network tools based on server mode
    if [ "$SERVER_MODE" = false ]; then
        pacstrap /mnt os-prober xdg-user-dirs
    fi

    if [ "$LAPTOP_MODE" = true ]; then
        pacstrap /mnt iwd
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

setup_system() {
    install_base_system
    install_essentials
    generate_fstab
    set_keymap
}