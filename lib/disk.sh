#!/bin/bash

### FUNCTION: Partition Disk Automatically ###
auto_partition() {
    # Early return if partitioning is not needed
    if [[ "$PARTITION" == "false" ]]; then
        return
    fi

    step "Automatic disk partitioning"
    info "Partitioning $DISK for UEFI + GRUB installation..."

    wipefs --all --force "$DISK"
    parted "$DISK" --script mklabel gpt
    parted "$DISK" --script mkpart ESP fat32 1MiB 1024MiB
    parted "$DISK" --script set 1 esp on

    if [[ "$USE_SWAP" = true ]]; then
        if [[ "$ROOT_SIZE" = "100%" ]]; then
            # Root partition takes all space except SWAP_SIZE at the end
            parted "$DISK" --script mkpart PRIMARY "$FILESYSTEM" 1024MiB "-$SWAP_SIZE"
            parted "$DISK" --script mkpart SWAP linux-swap "-$SWAP_SIZE" 100%
        else
            # Custom root size, swap comes after root
            parted "$DISK" --script mkpart PRIMARY "$FILESYSTEM" 1024MiB "$ROOT_SIZE"
            parted "$DISK" --script mkpart SWAP linux-swap "$ROOT_SIZE" "$(( $(numfmt --from=iec "$ROOT_SIZE") + $(numfmt --from=iec "$SWAP_SIZE") ))B"
        fi
    else
        # No swap, root takes all remaining space
        parted "$DISK" --script mkpart PRIMARY "$FILESYSTEM" 1024MiB "$ROOT_SIZE"
    fi

    success "Disk partitioning completed."
}

### FUNCTION: Format Partitions ###
format_partitions() {
    if [[ "$DISK" =~ nvme ]]; then
    part_prefix="p"
    else
        part_prefix=""
    fi

    step "Formatting partitions"
    info "Formatting EFI, root, and optional swap partitions..."

    # EFI Partition (first partition)
    mkfs.fat -F32 "${DISK}${part_prefix}${EFI}"

    # Root Partition (second partition)
    mkfs.ext4 -F "${DISK}${part_prefix}${ROOT}"

    # Swap Partition (third partition)
    if [[ "$USE_SWAP" = true ]]; then
        mkswap "${DISK}${part_prefix}${SWAP}"
        swapon "${DISK}${part_prefix}${SWAP}"
    fi

    success "Formatting complete."
}

### FUNCTION: Mount Partitions ###
mount_partitions() {
    if [[ "$DISK" =~ nvme ]]; then
        part_prefix="p"
    else
        part_prefix=""
    fi

    step "Mounting partitions"
    info "Mounting root and EFI partitions to /mnt and /mnt/boot..."

    # Mount root partition
    mount "${DISK}${part_prefix}${ROOT}" /mnt

    # Create & mount EFI boot partition
    mkdir -p /mnt/boot
    mount "${DISK}${part_prefix}${EFI}" /mnt/boot

    # Swap is already enabled by swapon
    success "Mounting complete."
}

### FUNCTION: Manual Partitioning ###
manual_partition() {
    step "Manual partitioning mode"
    info "Please create your partitions using tools like 'cfdisk', 'fdisk', or 'parted'."
    info "Make sure to create and format:"
    info "- EFI partition (usually FAT32, ~1024MiB)"
    info "- Root partition (ext4 recommended)"
    info "- Optional swap partition"
    echo
    info "You will now be dropped into a shell. Type 'exit' when done."
    press_enter "Press Enter to open a shell..."

    if [ -t 0 ]; then
        bash
    else
        bash < /dev/tty
    fi

    info "Exited manual partition shell. Continuing setup..."
}

### FUNCTION: Select Disk ###
select_disk() {
    step "Disk selection"
    info "Available disks:"
    lsblk -d -n -p -o NAME,SIZE | grep -E "/dev/(sd|nvme|vd)"

    DISK=$(ask_user "Enter the disk to install Arch Linux on" "$DISK")

    if [[ ! -b "$DISK" ]]; then
        error "Selected disk $DISK does not exist!"
        exit 1
    fi

    info "Selected disk: $DISK"
}

### FUNCTION: Set Partition Variables After Manual Partitioning ###
set_partition_variables() {
    step "Set partition variables"

    safe_read EFI "Enter EFI partition number (e.g., 1): "
    safe_read ROOT "Enter root partition number (e.g., 2): "

    if [[ "$USE_SWAP" == true ]]; then
        safe_read SWAP "Enter swap partition number (e.g., 3): "
    fi

    export EFI ROOT SWAP
}


### FUNCTION: Disk Setup Flow ###
setup_disk() {
    step "Disk setup"

    if [[ "$UNATTENDED" == true ]]; then
        auto_partition
        format_partitions
        mount_partitions
        return
    fi

    step "Disk partitioning options"
    info "1) Use default disk ($DISK) and auto-partition"
    info "2) Select a different disk and auto-partition"
    info "3) Manually partition the disk"

    CHOICE=$(ask_user "Choose an option (1/2/3)" "1")

    case "$CHOICE" in
        1) auto_partition && format_partitions && mount_partitions ;;
        2) select_disk && auto_partition && format_partitions && mount_partitions ;;
        3) manual_partition && set_partition_variables && format_partitions && mount_partitions ;;
        *) error "Invalid disk partitioning option selected, exiting."; exit 1 ;;
    esac
}