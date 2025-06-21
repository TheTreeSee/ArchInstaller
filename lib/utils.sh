#!/bin/bash

safe_read() {
  local varname="$1"
  local prompt="$2"
  local default="$3"
  local input

  if [ -t 0 ]; then
    # TTY available, use normal read
    read -r -p "$prompt" input
  else
    # No TTY? Reroute to real terminal
    echo -n "$prompt" > /dev/tty
    read -r input < /dev/tty
  fi

  # Use default if nothing entered
  if [ -z "$input" ] && [ -n "$default" ]; then
    input="$default"
  fi

  # Set variable using indirect expansion
  printf -v "$varname" '%s' "$input"
}

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