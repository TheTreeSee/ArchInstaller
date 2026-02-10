#!/bin/bash

system_check() {
    step "Running system checks"

    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root!"
        exit 1
    fi

    if [ ! -d /sys/firmware/efi ]; then
        error "UEFI firmware not detected! Please boot in UEFI mode."
        exit 1
    fi
}