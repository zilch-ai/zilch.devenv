#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

# Dependencies (sub modules)
source ./.system/config.sh
source ./.system/shell.sh

# Check if scoop is ready
SCOOP_READY=""
function scoop_ready()
{
    # Check if scoop ready status is set (cached)
    if [ -n "$SCOOP_READY" ]; then
        return $([ "$SCOOP_READY" -eq 1 ] && echo 0 || echo 1)
    fi

    # Check if scoop is installed and available in PATH
    local binpath=$(shell_binpath "ps" "scoop")
    if [ -z "$binpath" ]; then
        error "Scoop is not installed or not available in PATH."
        error "Please ensure Scoop is properly installed."
        SCOOP_READY=0
        return 1
    fi

    # Set the scoop ready status
    SCOOP_READY=1
    return 0
}

# Cleanup to remove all outdated apps and cache
function scoop_cleanup()
{
    # Check usage with correct arguments as inputs
    if [ $# -gt 1 ]; then
        usage "Usage: ${FUNCNAME[0]} [<app>]"
        usage "- <app>: The optional app name to cleanup."
        return 1
    fi
    local app="${1:---all}"

    # Check if scoop is ready
    scoop_ready || return 1

    # Cleanup scoop cache and temp files
    powershell.exe -Command "scoop cleanup $app"
    if [ $? -ne 0 ]; then
        error "Failed to cleanup scoop apps. Please check the output above for details."
        return 1
    fi
    return 0
}

# Update all installed scoop apps
function scoop_update()
{
    # Check usage with correct arguments as inputs
    if [ $# -gt 1 ]; then
        usage "Usage: ${FUNCNAME[0]} [<app>]"
        usage "- <app>: The optional app name to update."
        return 1
    fi
    local app="${1}"

    # Check if scoop is ready
    scoop_ready || return 1

    # Update all installed scoop apps
    powershell.exe -Command "scoop update $app"
    if [ $? -ne 0 ]; then
        error "Failed to update some scoop apps. Please check the output above for details."
        return 1
    fi

    # Cleanup outdated app and cache if need
    if [ -n "$app" ]; then
        scoop_cleanup "$app" || warn "Failed to cleanup scoop apps."
    fi
    return 0
}

# Setup the missing scoop buckets if need
function scoop_buckets()
{
    # Check usage with correct arguments as inputs
     if [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <filename>"
        usage "- <filename>: The configuration file contains the list of buckets to add."
        return 1
    fi

    # Check if the file exists and is readable
    local BUCKETS="$1"
    if [ ! -f "$BUCKETS" ]; then
        error "File '$BUCKETS' not found or is not readable."
        return 1
    fi
    if [ ! -r "$BUCKETS" ]; then
        error "Cannot read file '$BUCKETS'."
        return 1
    fi

    # Check if scoop is ready
    scoop_ready || return 1

    # Get the list of existing scoop buckets
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
            error "Failed to add or ensure bucket $name. Please check manually."
            return 1
        fi
    done
}

# List all installed scoop apps
function scoop_list()
{
    # Check usage with correct arguments as inputs
    if [ $# -gt 1 ]; then
        usage "Usage: ${FUNCNAME[0]} [<query>|<app!>]"
        usage "- <query>: The optional query string to filter the list of installed apps."
        usage "- <app!>: The app name (end with '!') for exact match of installed apps."
        return 1
    fi
    local query exact
    [[ "$1" == *! ]] && exact=1 query="${1%!}" || exact=0 query="$1"
    
    # Check if scoop is ready
    scoop_ready || return 1

    # Fetch the list of installed scoop apps and display
    local output
    output=$(powershell.exe -Command 'scoop list $query')
    if [ $? -ne 0 ]; then
        error "Failed to list installed scoop apps."
        return 1
    fi

    # Parse the output and store the list of installed apps
    local installed_apps
    output=$(echo "$output" | awk 'NR>4 {print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\r//g' | sed '/^$/d')
    IFS=$'\n' mapfile -t installed_apps <<< "$output"
    if [ ${#installed_apps[@]} -eq 0 ]; then
        trace "No scoop apps found."
        return 0
    fi
    trace "Scoop Apps (Installed, scoop_list)" installed_apps

    # Output the list of installed apps if exact match is not required
    if [ $exact -eq 0 ]; then
        IFS=$'\n'; echo "${installed_apps[*]}"
        return 0
    fi

    # Filter the list of installed apps if exact match is required
    for app in "${installed_apps[@]}"; do
        if [ "$app" == "$query" ]; then
            echo "$app"
            break
        fi
    done
    return 0
}

# Check if scoop app is installed
function scoop_binpath()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <app> [<command>]"
        usage "- <app>: The name of the scoop app to check."
        usage "- <command>: The command to check for in the app."
        return 1
    fi
    local app="$1"

    # Check if scoop is ready
    scoop_ready || return 1

    # Check if the app is installed
    if [ -z "$(scoop_list "$app!")" ]; then
        error "Scoop app '$app' is not installed."
        return 1
    fi

    local command="${2:-$app}"
    trace "Scoop App" "$app"
    trace "Scoop Command" "$command"
    local output=$(shell_binpath "ps" "$command")
    local binpath
    if [ -z "$output" ]; then
        error "Command '$command' for '$app' is not found."
        return 1
    fi
    while IFS= read -r binpath; do
        binpath=$(echo "$binpath" | tr -d '\r\n')
        trace "BINPATH Candidate" $binpath

        if [[ "$binpath" == *"\\scoop\\apps\\$app"* ]]; then
            trace "BINPATH ('$command') of '$app'" "$binpath"
            echo "$binpath"
            return 0
        fi
    done <<< "$output"

    # Return the bin path
    error "All binpath candidates for '$app' are not under scoop apps."
    return 1
}

# Install all missing scoop apps from the list
function scoop_apps()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <filename>"
        usage "- <filename>: The configuration file contains the list of apps to install."
        return 1
    fi

    # Check if scoop is ready
    scoop_ready || return 1

    # Define local variables used within the function
    local output
    local -a apps
    local -a installed_apps
    local -a missing_apps

    # Load the list of apps
    output=$(load_cfg "$1" | tr -d '\n') || { error "Failed to load the list of scoop apps."; return 1; }
    IFS=$' ' read -r -a apps <<< "$output"
    if [ ${#apps[@]} -eq 0 ]; then
        warn "No apps found in the config file."
        return 0
    fi
    trace "Scoop Apps (Required)" apps

    # Get the list of installed apps
    output=$(scoop_list) || return 1;
    IFS=$'\n' mapfile -t installed_apps <<< "$output"
    trace "Scoop Apps (Installed, scoop_apps)" installed_apps

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
        echo "All required scoop apps are already installed."
        return 0
    fi
    trace "Scoop Apps (Missing)" missing_apps

    # Install all missing apps from the list
    echo "Installing all missing scoop apps..."
    powershell.exe -Command "scoop install ${missing_apps[*]}"
}
