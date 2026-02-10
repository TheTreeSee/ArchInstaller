#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/thetreesee/archinstaller/main"
OVERWRITE=false

usage() {
  cat <<EOF
Usage: $0 [-u URL] [-o] [-h]

Options:
  -u URL    Set custom base URL (default: GitHub)
  -o        Overwrite existing files
  -h        Show this help message
EOF
  exit 1
}

while getopts ":u:oh" opt; do
  case $opt in
    u)
      REPO_URL="$OPTARG"
      ;;
    o)
      OVERWRITE=true
      ;;
    h)
      usage
      ;;
    \?)
      echo "[ERROR] Unknown option: -$OPTARG"
      usage
      ;;
    :)
      echo "[ERROR] Option -$OPTARG requires an argument."
      usage
      ;;
  esac
done

TEMP_DIR="/tmp/archinstaller"
echo "[INFO] Using temporary directory: $TEMP_DIR"
rm -rf "$TEMP_DIR" 2>/dev/null
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

declare -a FILES=(
    "config/conf.sh"
    "config/settings.conf"
    "config/checks.sh"
    "lib/configure.sh"
    "lib/disk.sh"
    "lib/system.sh"
    "lib/network.sh"
    "lib/security.sh"
    "lib/utils.sh"
    "assets/00-wheel"
)

echo "[INFO] Downloading installer files from: $REPO_URL"

# add settings.conf.env to FILES if overwrite is true
if [[ "$OVERWRITE" == true ]]; then
    echo "[INFO] Overwrite mode enabled; checking for settings.conf.env..."
    # check if settings.conf.env exists remotely
    if curl --head --silent --fail "$REPO_URL/config/settings.conf.env" >/dev/null; then
        echo "[INFO] Found remote config/settings.conf.env; it will be downloaded and applied."
        FILES+=("config/settings.conf.env")
    else
        echo "[WARN] config/settings.conf.env does not exist in the repository, disabling overwrite."
        OVERWRITE=false
    fi
fi

for file in "${FILES[@]}"; do
    echo "[INFO] Fetching $file..."
    mkdir -p "$(dirname "$file")"
    curl -s "$REPO_URL/$file" -o "$file"
    chmod +x "$file"
done

echo "[INFO] All installer components downloaded."

# Source all files
echo "[INFO] Sourcing configuration and library scripts..."
source config/conf.sh
source config/settings.conf #? why is this sourced here?
source config/checks.sh
source lib/utils.sh
source lib/disk.sh
source lib/configure.sh
source lib/system.sh
source lib/network.sh
source lib/security.sh

step "Running pre-install system checks"
# config/checks.sh
system_check

step "Loading and confirming configuration"
# config/conf.sh
config_setup

step "Setting up disk layout"
# lib/disk.sh
setup_disk

step "Installing base system and essentials"
# lib/system.sh
setup_system

step "Applying base system configuration in chroot"
# lib/configure.sh
cp assets/00-wheel /mnt/etc/sudoers.d/00-wheel
arch-chroot /mnt /bin/bash < lib/configure.sh

step "Applying security hardening in chroot"
# lib/security.sh
arch-chroot /mnt /bin/bash < lib/security.sh

step "Configuring network"
# lib/network.sh
setup_network

step "Finalizing installation"
# lib/utils.sh
finalize_installation

# Cleanup
#* rm -rf "$TEMP_DIR"
