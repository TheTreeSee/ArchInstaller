#!/bin/bash

### CONFIGURABLE SETTINGS ###
UNATTENDED=true             # If true, script runs without prompts
SERVER_MODE=false           # If true, installs systemd-networkd & iwd
HOSTNAME="archmachine"      # Default hostname
USERNAME="admin"            # Default user
PASSWORD="password"         # Set to empty for manual input
CPU_VENDOR="amd"           # CPU vendor (intel/amd) for microcode
KERNEL="linux"             # Kernel choice
DISK="/dev/sda"            # Default disk for installation
FILESYSTEM="ext4"          # Default filesystem
ROOT_SIZE="100%"           # Size for root partition
USE_SWAP=false             # Enable swap partition
SWAP_SIZE="4G"             # Size for swap partition
TIMEZONE="UTC"             # Default timezone
LOCALE="en_US.UTF-8"       # Default locale
KEYMAP="colemak"           # Keyboard layout
PACKEGES=""                # List of extra packages