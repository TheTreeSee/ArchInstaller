#!/bin/bash

### FUNCTION: Partition Disk Automatically ###
auto_partition() {
    # Early return if partitioning is not needed
    if [[ "$PARTITION" == "false" ]]; then
        return
    fi

    echo "Partitioning $DISK for UEFI + GRUB installation..."

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

    echo "Disk partitioning completed."
}

### FUNCTION: Format Partitions ###
format_partitions() {
    if [[ "$DISK" =~ nvme ]]; then
    part_prefix="p"
    else
        part_prefix=""
    fi

    echo "Formatting partitions..."

    # EFI Partition (first partition)
    mkfs.fat -F32 "${DISK}${part_prefix}${EFI}"

    # Root Partition (second partition)
    mkfs.ext4 -F "${DISK}${part_prefix}${ROOT}"

    # Swap Partition (third partition)
    if [[ "$USE_SWAP" = true ]]; then
        mkswap "${DISK}${part_prefix}${SWAP}"
        swapon "${DISK}${part_prefix}${SWAP}"
    fi

    echo "Formatting complete."
}

### FUNCTION: Mount Partitions ###
mount_partitions() {
    if [[ "$DISK" =~ nvme ]]; then
        part_prefix="p"
    else
        part_prefix=""
    fi

    echo "Mounting partitions..."

    # Mount root partition
    mount "${DISK}${part_prefix}${ROOT}" /mnt

    # Create & mount EFI boot partition
    mkdir -p /mnt/boot
    mount "${DISK}${part_prefix}${EFI}" /mnt/boot

    # Swap is already enabled by swapon
    echo "Mounting complete."
}

### FUNCTION: Manual Partitioning ###
manual_partition() {
    echo "=== Manual Partitioning Mode ==="
    echo "Please create your partitions using tools like 'cfdisk', 'fdisk', or 'parted'."
    echo "Make sure to create and format:"
    echo "- EFI partition (usually FAT32, ~1024MiB)"
    echo "- Root partition (ext4 recommended)"
    echo "- Optional swap partition"
    echo
    echo "You will now be dropped into a shell. Type 'exit' when done."
    read -rp "Press Enter to open a shell..."

    bash

    echo "Exited manual partition shell. Continuing setup..."
}

### FUNCTION: Select Disk ###
select_disk() {
    echo "Available Disks:"
    lsblk -d -n -p -o NAME,SIZE | grep -E "/dev/(sd|nvme|vd)"

    DISK=$(ask_user "Enter the disk to install Arch Linux on" "$DISK")

    if [[ ! -b "$DISK" ]]; then
        echo "Error: Selected disk $DISK does not exist!" >&2
        exit 1
    fi

    echo "Selected disk: $DISK"
}

### FUNCTION: Set Partition Variables After Manual Partitioning ###
set_partition_variables() {
    echo "=== Set Partition Variables ==="

    read -rp "Enter EFI partition number (e.g., 1): " EFI
    read -rp "Enter root partition number (e.g., 2): " ROOT

    if [[ "$USE_SWAP" == true ]]; then
        read -rp "Enter swap partition number (e.g., 3): " SWAP
    fi

    export EFI ROOT SWAP
}


### FUNCTION: Disk Setup Flow ###
setup_disk() {
    if [[ "$UNATTENDED" == true ]]; then
        auto_partition
        format_partitions
        mount_partitions
        return
    fi

    echo "Disk Partitioning Options:"
    echo "1) Use default disk ($DISK) and auto-partition"
    echo "2) Select a different disk and auto-partition"
    echo "3) Manually partition the disk"

    CHOICE=$(ask_user "Choose an option (1/2/3)" "1")

    case "$CHOICE" in
        1) auto_partition ;;
        2) select_disk && auto_partition && format_partitions && mount_partitions ;;
        3) manual_partition && set_partition_variables && format_partitions && mount_partitions ;;
        *) echo "Invalid option, exiting." && exit 1 ;;
    esac
}