#!/bin/bash

### FUNCTION: Ask User for Input ###
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

    # todo: uncomment when testing is done
    # if [ "$UNATTENDED" = true ]; then
    #     echo "Unattended mode enabled. Rebooting..."
    #     reboot
    # else
        read -p "Installation complete! Press Enter to reboot or Ctrl+C to stay in the live environment..."
        reboot
    # fi
}