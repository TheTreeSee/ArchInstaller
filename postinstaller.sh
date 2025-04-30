#!/bin/bash
echo "Running postinstall script..."

# EXAMPLE: install yay and a few packages
pacman -Syu --noconfirm

# Other setup steps here...
# echo "Customizing system..."
# ...

# Cleanup: disable service and remove self
systemctl disable post-install.service
rm -f /etc/systemd/system/post-install.service
rm -f /root/post-install.sh

