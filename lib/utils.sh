#!/bin/bash

### GENERIC LOGGING HELPERS ###

info() {
  echo "[INFO] $*"
}

step() {
  echo
  echo "=============================="
  echo "[STEP] $*"
  echo "=============================="
}

success() {
  echo "[OK] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

error() {
  echo "[ERROR] $*" >&2
}

### SAFE INPUT HELPERS ###

safe_read() {
  local varname="$1"
  local prompt="$2"
  local default="$3"
  local hidden="$4"  # if set to "true", hide input
  local input

  if [ -t 0 ]; then
    # Interactive TTY available
    if [[ "$hidden" == "true" ]]; then
      read -r -s -p "$prompt" input
      echo  # move to new line after silent input
    else
      read -r -p "$prompt" input
    fi
  else
    # No TTY? Reroute to real terminal
    if [[ "$hidden" == "true" ]]; then
      echo -n "$prompt" > /dev/tty
      stty -echo < /dev/tty
      read -r input < /dev/tty
      stty echo < /dev/tty
      echo > /dev/tty
    else
      echo -n "$prompt" > /dev/tty
      read -r input < /dev/tty
    fi
  fi

  # Use default if nothing entered
  if [ -z "$input" ] && [ -n "$default" ]; then
    input="$default"
  fi

  # Set variable using indirect expansion
  printf -v "$varname" '%s' "$input"
}

press_enter() {
  safe_read _dummy "$1" ""
}

### FUNCTION: Ask User for Input ###
ask_user() {
    local prompt="$1"
    local default="$2"
    if [ "$UNATTENDED" = true ]; then
        echo "$default"
        return
    fi
    safe_read response "$prompt [$default]: " default
    echo "$response"
}

### FUNCTION: Final Steps Before Reboot ###
finalize_installation() {
    step "Finalizing installation"
    info "Unmounting partitions from /mnt..."
    umount -R /mnt

    info "Installation summary:"
    info "- Hostname: $HOSTNAME"
    info "- Username: $USERNAME"
    info "- Keyboard Layout: $KEYMAP"
    info "- Server Mode: $SERVER_MODE"

    # todo: uncomment when testing is done
    # if [ "$UNATTENDED" = true ]; then
    #     info "Unattended mode enabled. Rebooting..."
    #     reboot
    # else
        press_enter "Installation complete! Press Enter to reboot or Ctrl+C to stay in the live environment..."
        reboot
    # fi
}