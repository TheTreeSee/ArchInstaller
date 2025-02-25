#!/bin/bash

### CONFIGURABLE SETTINGS ###
DISK="/dev/sda"             # Default disk for installation
HOSTNAME="archmachine"      # Default hostname
USERNAME="admin"            # Default user
FILESYSTEM="ext4"           # Default filesystem (ext4, btrfs, etc.)
USE_SWAP=true               # Enable swap partition
UNATTENDED=false            # If true, script runs without prompts
KEYMAP="colemak"            # Keyboard layout (e.g., us, colemak, de-latin1, etc.)
SERVER_MODE=false           # If true, installs systemd-networkd & iwd (minimal server setup)
PASSWORD=""                 # Set to empty for manual input, or define a password
TIMEZONE="UTC"              # Default timezone
LOCALE="en_US.UTF-8"        # Default locale
ROOT_SIZE="40G"             # Size for root partition (when auto-partitioning)
SWAP_SIZE="4G"              # Size for swap partition
CPU_VENDOR="intel"          # CPU vendor (intel/amd) for microcode
KERNEL="linux"              # Kernel choice (linux/linux-lts/linux-zen/linux-hardened)


### FUNCTION: Check if running as root ###
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root!" >&2
        exit 1
    fi
}

### FUNCTION: Ask user for confirmation ###
ask_user() {
    local prompt="$1"
    local default="$2"
    if [ "$UNATTENDED" = true ]; then
        echo "$default"
        return
    fi
    read -rp "$prompt [$default]: " response
    echo "${response:-$default}"
}

### FUNCTION: Select Disk ###
select_disk() {
    echo "Available Disks:"
    lsblk -d -n -p -o NAME,SIZE | grep -E "/dev/(sd|nvme|vd)"

    DISK=$(ask_user "Enter the disk to install Arch Linux on" "$DISK")

    if [ ! -b "$DISK" ]; then
        echo "Error: Selected disk $DISK does not exist!" >&2
        exit 1
    fi

    echo "Selected disk: $DISK"
}

### FUNCTION: Partition Disk Automatically ###
auto_partition() {
    echo "Partitioning $DISK for UEFI + GRUB installation..."

    # Wipe the disk (CAUTION: This will erase everything)
    wipefs --all --force "$DISK"
    parted "$DISK" --script mklabel gpt
    parted "$DISK" --script mkpart ESP fat32 1MiB 512MiB
    parted "$DISK" --script set 1 esp on
    parted "$DISK" --script mkpart PRIMARY "$FILESYSTEM" 512MiB 100%

    if [ "$USE_SWAP" = true ]; then
        parted "$DISK" --script mkpart SWAP linux-swap 1000MiB 4096MiB
    fi

    echo "Disk partitioning completed."
}

### FUNCTION: Manual Partitioning ###
manual_partition() {
    echo "Launching interactive partitioning tool..."
    cfdisk "$DISK"
    echo "Please ensure partitions are created properly before proceeding."
    read -rp "Press Enter to continue..."
}

### FUNCTION: Disk Setup Flow ###
setup_disk() {
    if [ "$UNATTENDED" = true ]; then
        auto_partition
        return
    fi

    echo "Disk Partitioning Options:"
    echo "1) Use default disk ($DISK) and auto-partition"
    echo "2) Select a different disk"
    echo "3) Manually partition the disk"

    CHOICE=$(ask_user "Choose an option (1/2/3)" "1")

    case "$CHOICE" in
        1) auto_partition ;;
        2) select_disk && auto_partition ;;
        3) select_disk && manual_partition ;;
        *) echo "Invalid option, exiting." && exit 1 ;;
    esac
}

### FUNCTION: Format Partitions ###
format_partitions() {
    echo "Formatting partitions..."

    # EFI Partition (first partition)
    mkfs.fat -F32 "${DISK}1"

    # Root Partition (second partition)
    case "$FILESYSTEM" in
        ext4)
            mkfs.ext4 -F "${DISK}2"
            ;;
        btrfs)
            mkfs.btrfs -f "${DISK}2"
            ;;
        xfs)
            mkfs.xfs -f "${DISK}2"
            ;;
        *)
            echo "Error: Unsupported filesystem type '$FILESYSTEM'" >&2
            exit 1
            ;;
    esac

    # Swap Partition (third partition)
    if [ "$USE_SWAP" = true ]; then
        mkswap "${DISK}3"
        swapon "${DISK}3"
    fi

    echo "Formatting complete."
}

### FUNCTION: Mount Partitions ###
mount_partitions() {
    echo "Mounting partitions..."

    # Mount root partition
    mount "${DISK}2" /mnt

    # Create & mount EFI boot partition
    mkdir -p /mnt/boot
    mount "${DISK}1" /mnt/boot

    # Swap is already enabled by swapon
    echo "Mounting complete."
}


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
        pacstrap /mnt systemd-networkd
    else
        pacstrap /mnt iwd systemd-networkd systemd-resolved os-prober
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
        us)
            echo "KEYMAP=us" > /mnt/etc/vconsole.conf
            ;;
        azerty)
            echo "KEYMAP=fr" > /mnt/etc/vconsole.conf
            ;;
        *)
            echo "Invalid keymap selected, defaulting to US."
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

    # Enable network services
    systemctl enable systemd-networkd
    systemctl enable systemd-resolved
    [ "$SERVER_MODE" = false ] && systemctl enable iwd

    # Install and configure GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
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

    if [ "$UNATTENDED" = true ]; then
        echo "Unattended mode enabled. Rebooting..."
        reboot
    else
        read -p "Installation complete! Press Enter to reboot or Ctrl+C to stay in the live environment..."
        reboot
    fi
}

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

# Start script execution
check_root
setup_disk
format_partitions
mount_partitions
install_base_system
install_essentials
generate_fstab
set_keymap
configure_security
configure_system
finalize_installation