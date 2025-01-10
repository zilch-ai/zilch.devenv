#!/bin/bash

# Check if the script is being sourced
source .system/reentry.sh
reentry "$0" || return 0

# Check if scoop is installed
function scoop_exists()
{
    if ! powershell.exe -Command "Get-Command scoop" &>/dev/null; then
        echo "Error: Scoop is not installed or not available in PATH. Please ensure Scoop is properly installed."
        return 1
    fi
}

# Update scoop itself
function scoop_self()
{
    # Check if scoop is installed
    scoop_exists || return 1

    # Update scoop itself
    scoop update
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update scoop. Please check your configuration or internet connection."
        return 1
    fi
}

# Setup the missing scoop buckets if need
function scoop_buckets()
{
    # Check usage with correct arguments as inputs
     if [ -z "$1" ]; then
        echo "Usage: $0 <filename>"
        echo "- <filename>: The configuration file contains the list of buckets to add."
        return 1
    fi

    # Check if the file exists and is readable
    local BUCKETS="$1"
    if [ ! -f "$BUCKETS" ]; then
        echo "Error: File '$BUCKETS' not found or is not readable."
        return 1
    fi
    if [ ! -r "$BUCKETS" ]; then
        echo "Error: Cannot read file '$BUCKETS'."
        return 1
    fi

    # Check if scoop is installed
    scoop_exists || return 1

    local existing=$(powershell.exe -Command "scoop bucket list")

    # Ensure all scoop buckets in file are added
    tail -n +2 "$BUCKETS" | while IFS=',' read -r name uri; do
        if [ -z "$name" ]; then
            continue
        fi
        if echo "$existing" | grep -q "$name"; then
            echo "Bucket '$name' already exists. Skipping..."
            continue
        fi    

        if [ -z "$uri" ]; then
            echo "Add new scoop bucket '$name'..."
            powershell.exe -Command "scoop bucket add $name"
        else
            echo "Add new scoop bucket '$name' at '$uri'..."
            powershell.exe -Command "scoop bucket add $name $uri"
        fi

        if [ $? -ne 0 ]; then
            echo "Error: Failed to add or ensure bucket $name. Please check manually."
            return 1
        fi
    done
}

# Install all missing scoop apps from the list
function scoop_apps()
{
    # Check usage with correct arguments as inputs
     if [ -z "$1" ]; then
        echo "Usage: $0 <filename>"
        echo "- <filename>: The configuration file contains the list of apps to install."
        return 1
    fi

    # Check if scoop is installed
    scoop_exists || return 1

    # Define local variables used within the function
    local output
    local -a apps
    local -a installed_apps
    local -a missing_apps

    # Load the list of apps
    source ./.system/config.sh
    output=$(load_cfg "$1" | tr -d '\n') || { echo "Error: Failed to load the list of scoop apps."; return 1; }
    IFS=$' ' read -r -a apps <<< "$output"
    if [ ${#apps[@]} -eq 0 ]; then
        echo "Warn: No apps found in the config file."
        return 0
    fi

    # Get the list of installed apps
    output=$(powershell.exe -Command 'scoop list' | awk 'NR>4 {print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') \
    || { echo "Error: Failed to list installed scoop apps."; return 1; }
    IFS=$'\n' read -r -d '' -a installed_apps <<< "$output"

    # Check for missing apps
    missing_apps=()
    for item in "${apps[@]}"; do
        IFS='/' read -r bucket app <<< "$item"
        if [ -z "$app" ]; then
            bucket=""
            app="$item"
        fi

        if [[ " ${installed_apps[@]} " =~ " $app " ]]; then
            echo "App '$item' already installed. Skipping..."
            continue
        fi

        missing_apps+=("$item")
    done
    if [ ${#missing_apps[@]} -eq 0 ]; then
        echo "All listed scoop apps are already installed."
        return 0
    fi

    # Install all missing apps from the list
    echo "Installing all missing scoop apps..."
    powershell.exe -Command "scoop install ${missing_apps[*]}"
}

# Update all installed scoop apps
function scoop_all()
{
    # Check if scoop is installed
    scoop_exists || return 1

    # Update all installed scoop apps
    powershell.exe -Command "scoop update --all"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update some scoop apps. Please check the output above for details."
        return 1
    fi
}
