#!/bin/bash

# Bootstrap script to download and run the installer
REPO_URL="https://raw.githubusercontent.com/thetreesee/archinstaller/main"
TEMP_DIR="/tmp/archinstaller"

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# Download all required files
declare -a FILES=(
    "config/settings.sh"
    "config/checks.sh"
    "lib/disk.sh"
    "lib/system.sh"
    "lib/network.sh"
    "lib/security.sh"
    "lib/utils.sh"
)

for file in "${FILES[@]}"; do
    mkdir -p "$(dirname "$file")"
    curl -s "$REPO_URL/$file" -o "$file"
    chmod +x "$file"
done

# Source all files
source config/settings.sh
source config/checks.sh
source lib/utils.sh
source lib/disk.sh
source lib/system.sh
source lib/network.sh
source lib/security.sh

# Main installation flow
system_check #
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

# Cleanup
rm -rf "$TEMP_DIR"
