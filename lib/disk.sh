#!/bin/bash

### FUNCTION: Partition Disk Automatically ###
auto_partition() {
    echo "Partitioning $DISK for UEFI + GRUB installation..."

    # Wipe the disk (CAUTION: This will erase everything)
    wipefs --all --force "$DISK"
    parted "$DISK" --script mklabel gpt
    parted "$DISK" --script mkpart ESP fat32 1MiB 512MiB
    parted "$DISK" --script set 1 esp on

    if [ "$USE_SWAP" = true ]; then
        if [ "$ROOT_SIZE" = "100%" ]; then
            # Root partition takes all space except SWAP_SIZE at the end
            parted "$DISK" --script mkpart PRIMARY "$FILESYSTEM" 512MiB "-$SWAP_SIZE"
            parted "$DISK" --script mkpart SWAP linux-swap "-$SWAP_SIZE" 100%
        else
            # Custom root size, swap comes after root
            parted "$DISK" --script mkpart PRIMARY "$FILESYSTEM" 512MiB "$ROOT_SIZE"
            parted "$DISK" --script mkpart SWAP linux-swap "$ROOT_SIZE" "$(( $(numfmt --from=iec "$ROOT_SIZE") + $(numfmt --from=iec "$SWAP_SIZE") ))B"
        fi
    else
        # No swap, root takes all remaining space
        parted "$DISK" --script mkpart PRIMARY "$FILESYSTEM" 512MiB "$ROOT_SIZE"
    fi

    echo "Disk partitioning completed."
}

### FUNCTION: Manual Partitioning ###
# manual_partition() {
#     echo "Launching interactive partitioning tool..."
#     cfdisk "$DISK"
#     echo "Please ensure partitions are created properly before proceeding."
#     read -rp "Press Enter to continue..."
# }

### FUNCTION: Select Disk ###
# select_disk() {
#     echo "Available Disks:"
#     lsblk -d -n -p -o NAME,SIZE | grep -E "/dev/(sd|nvme|vd)"

#     DISK=$(ask_user "Enter the disk to install Arch Linux on" "$DISK")

#     if [ ! -b "$DISK" ]; then
#         echo "Error: Selected disk $DISK does not exist!" >&2
#         exit 1
#     fi

#     echo "Selected disk: $DISK"
# }

### FUNCTION: Disk Setup Flow ###
setup_disk() {
    if [ "$UNATTENDED" = true ]; then
        auto_partition
        return
    fi

    # echo "Disk Partitioning Options:"
    # echo "1) Use default disk ($DISK) and auto-partition"
    # echo "2) Select a different disk"
    # echo "3) Manually partition the disk"

    # CHOICE=$(ask_user "Choose an option (1/2/3)" "1")

    # case "$CHOICE" in
    #     1) auto_partition ;;
    #     2) select_disk && auto_partition ;;
    #     3) select_disk && manual_partition ;;
    #     *) echo "Invalid option, exiting." && exit 1 ;;
    # esac
}

### FUNCTION: Format Partitions ###
format_partitions() {
    echo "Formatting partitions..."

    # EFI Partition (first partition)
    mkfs.fat -F32 "${DISK}1"

    # Root Partition (second partition)
    mkfs.ext4 -F "${DISK}2"

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