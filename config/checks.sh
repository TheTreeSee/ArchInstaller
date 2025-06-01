#!/bin/bash

system_check() {
    echo "Running system checks..."

    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root!" >&2
        exit 1
    fi

    if [ ! -d /sys/firmware/efi ]; then
        echo "UEFI firmware not detected! Please boot in UEFI mode."
        exit 1
    fi
}