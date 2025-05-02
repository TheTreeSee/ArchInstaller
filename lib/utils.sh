#!/bin/bash

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