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
      echo "❌ Unknown option: -$OPTARG"
      usage
      ;;
    :)
      echo "❌ Option -$OPTARG requires an argument."
      usage
      ;;
  esac
done

TEMP_DIR="/tmp/archinstaller"
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

# add settings.conf.env to FILES if overwrite is true
if [[ "$OVERWRITE" == true ]]; then
    # check if settings.conf.env exists remotely
    if curl --head --silent --fail "$REPO_URL/config/settings.conf.env" >/dev/null; then
        FILES+=("config/settings.conf.env")
    else
        echo "Warning: config/settings.conf.env does not exist in the repository, skipping."
        OVERWRITE=false
    fi
fi

for file in "${FILES[@]}"; do
    mkdir -p "$(dirname "$file")"
    curl -s "$REPO_URL/$file" -o "$file"
    chmod +x "$file"
done


# Source all files
source config/conf.sh
source config/settings.conf #? why is this sourced here?
source config/checks.sh
source lib/utils.sh
source lib/disk.sh
source lib/configure.sh
source lib/system.sh
source lib/network.sh
source lib/security.sh


# config/checks.sh
#* system_check

# config/conf.sh
config_setup

# lib/disk.sh
setup_disk

# lib/system.sh
setup_system

# lib/security.sh
configure_security

# lib/configure.sh
cp assets/00-wheel /mnt/etc/sudoers.d/00-wheel
arch-chroot /mnt /bin/bash < lib/configure.sh

# lib/security.sh
arch-chroot /mnt /bin/bash < lib/security.sh

# lib/network.sh
setup_network

# lib/utils.sh
#! finalize_installation

# Cleanup
#* rm -rf "$TEMP_DIR"
