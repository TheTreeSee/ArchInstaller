#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/thetreesee/archinstaller/main"

usage() {
  echo "Usage: $0 [-u|--url <base_url>]"
  exit 1
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--url)
      if [[ -n $2 ]]; then
        REPO_URL="$2"
        shift 2
      else
        echo "Error: --url requires a value"
        usage
      fi
      ;;
    -o|--overwrite)
      OVERWRITE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
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
#* setup_disk

# lib/system.sh
# setup_system
#! install_base_system
#! install_essentials
#! generate_fstab
#! set_keymap
#! configure_security
#! configure_system
#! finalize_installation

# lib/configure.sh
arch-chroot /mnt /bin/bash < configure.sh

# Cleanup
#* rm -rf "$TEMP_DIR"
