#!/bin/bash

# Load settings from settings.conf into the current shell
get_config() {
    local filename="$1"

    # Check for config file
    if [[ ! -f $filename ]]; then
        echo "Config file not found: $filename" >&2
        exit 1
    fi

    # Export variables
    set -a
    source $filename
    set +a
}

# Function to display settings in a formatted way
display_settings() {
    local filename="$1"
    # Read all non-empty, non-comment lines from settings.conf
    while IFS='=' read -r var value; do
        # Skip comments and empty lines
        [[ $var =~ ^#.*$ || -z $var ]] && continue

        # Remove any trailing comments
        value=$(echo "$value" | sed -E 's/[[:space:]]*#.*$//')

        # Get value
        actual_value="${!var}"

        # Display variable and value
        printf "%-20s: %s\n" "$var" "$actual_value"
    done < $filename
}

# Function to get variables from config file
get_config_vars() {
    # Read the config file and extract variable names
    grep -v '^#' "config/settings.conf" | grep -v '^$' | cut -d'=' -f1
}

# Function to interactively configure settings
interactive_config() {
    if [[ "$RECONFIG" == false ]]; then
        return
    fi

    echo
    echo "Press Enter to keep current values or enter new values when prompted."

    # Get all variables from config file
    local vars=($(get_config_vars))
    local new_config=""

    # Loop through each variable
    for var in "${vars[@]}"; do
        # Get current value
        current_value="${!var}"

        # Special handling for password
        if [[ "$var" == "PASSWORD" ]]; then
            safe_read new_value "$var [$current_value]: " $current_value true
        else
            safe_read new_value "$var [$current_value]: " $current_value
        fi

        # Add to new config
        new_config+="$var=$new_value\n"
    done

    # Save changes to config file
    echo -e "$new_config" > "config/conf.conf"

    get_config "config/conf.conf"

    echo
    display_settings "config/conf.conf"
}

config_setup() {
    get_config "config/settings.conf"
    get_config "config/settings.conf.env" # overwrite settings with settings from env
    interactive_config
}