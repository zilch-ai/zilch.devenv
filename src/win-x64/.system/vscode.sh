#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

# Dependencies (sub modules)
source "$LAUNCH_ROOT/.system/shell.sh"
source "$LAUNCH_ROOT/.system/scoop.sh"

# Set the default vscode editor
VSCODE_APP=""
VSCODE_CMD=""
VSCODE_MARKET=""
VSCODE_BINPATH=""
VSCODE_READY=""

# Check if vscode is installed
function vscode_ready()
{
    # Check if vscode ready status is set (cached)
    if [ -n "$VSCODE_READY" ]; then
        return $([ "$VSCODE_READY" -eq 1 ] && echo 0 || echo 1)
    fi

    # Check if the vscode editor is set
    if [ -z "$VSCODE_BINPATH" ]; then
        error "The default vscode editor is not set."
        error "Please run 'vscode_default' to set the default vscode editor."
        VSCODE_READY=0
        return 1
    fi

    # Check if the vscode editor is installed and functional
    if ! shell_exec "cmd" "$VSCODE_BINPATH --version" --silent; then
        error "'$VSCODE_BINPATH' for vscode exists but is not functional."
        VSCODE_READY=0
        return 1
    fi

    # Set the vscode editor as ready
    VSCODE_READY=1
    return 0
}

# Switch the default vscode editor
function vscode_default()
{
    # Usage with correct arguments as inputs
    if [ -z "$1" ] || [ $# -gt 1 ]; then
        usage "Usage: ${FUNCNAME[0]} <app>"
        usage "- <app>: The app name of the vscode editor."
        return 1
    fi

    # Check if the editor is already set
    if [ "$VSCODE_APP" == "$1" ]; then
        echo "Skip to set the default vscode editor '$1': Already set."
        return 0
    fi

    # Set vscode settings based on the app name
    local app cmd market
    case $1 in
        "vscode" | "VSCode")
            app="vscode"
            cmd="code"
            market="vs-marketplace"
            ;;
        "vscodium" | "VSCodium")
            app="vscodium"
            cmd="codium"
            market="open-vsx"
            ;;
        "cursor" | "Cursor")
            app="cursor"
            cmd="code"
            market=""
            ;;
        *)
            error "Unrecognized vscode editor '$1'."
            return 1
            ;;
    esac

    # Check if scoop app is installed and get the scoop location
    local binpath=$(scoop_binpath "$app" "$cmd") || return 1
    if [ -z "$binpath" ]; then
        error "The vscode editor '$app' is not installed."
        return 1
    fi
    trace "BINPATH of vscode" "$binpath"

    # Set the vscode editor as the default editor
    export VSCODE_APP="$app"
    export VSCODE_CMD="$cmd"
    export VSCODE_MARKET="$market"
    export VSCODE_BINPATH="$binpath"
    trace "VSCODE_APP" "$VSCODE_APP"
    trace "VSCODE_CMD" "$VSCODE_CMD"
    trace "VSCODE_BINPATH" "$VSCODE_BINPATH"
    trace "VSCODE_MARKET" "$VSCODE_MARKET"
    
    # Check if the vscode editor is installed and functional
    vscode_ready || return 1
    return 0
}

# Get the latest version of the vscode extension from the marketplace
function vscode_latest()
{
    # Usage with correct arguments as inputs
    if [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <publisher>.<extension>"
        usage "- <publisher>: The name of the publisher of vscode extension."
        usage "- <extension>: The name of the vscode extension."
        return 1
    fi
    local PUBLISHER=$(echo "$1" | awk -F'.' '{print $1}')
    local EXTENSION=$(echo "$1" | awk -F'.' '{print $2}')
    if [[ -z "$PUBLISHER" || -z "$EXTENSION" ]]; then
        error "Unrecognized format of vscode extension '$1'."
        usage "Format: <publisher>.<extension>"
        usage "Example: ms-python.python"
        return 1
    fi

    # Extract 'pre-release' switch from name of the extension
    local PRE_RELEASE=0
    if [[ "$EXTENSION" == *'?' ]]; then
        EXTENSION="${EXTENSION%?}"
        PRE_RELEASE=1
    fi

    # Fetch the latest version from open-vsx.org
    if [ "$VSCODE_MARKET" == "open-vsx" ]; then
        local JSON=$(curl -s "https://open-vsx.org/api/$PUBLISHER/$EXTENSION/latest")
        local VERSION=$(echo "$JSON" | awk -F'"version":"' '{print $2}' | awk -F'"' '{print $1}')
        if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
            error "Failed to get the latest version of vscode extension '$1'."
            error "JSON:"
            error "$JSON"
            return 1
        fi
        echo "$VERSION"
        return 0
    fi

    # Fetch the latest version from marketplace.visualstudio.com
    if [ "$VSCODE_MARKET" == "vs-marketplace" ]; then
        # References of Visual Studio Marketplace API:
        # - https://github.com/microsoft/navcontainerhelper/blob/main/HelperFunctions.ps1
        # - https://github.com/microsoft/azure-devops-node-api/blob/master/api/interfaces/GalleryInterfaces.ts
        local request='
        {
            "filters":
            [
                {
                    "criteria":
                    [
                        { "filterType": 8, "value": "Microsoft.VisualStudio.Code" },
                        { "filterType": 7, "value": "'"$PUBLISHER.$EXTENSION"'" }
                    ],
                    "pageNumber": 1,
                    "pageSize": 50,
                    "sortBy": 0,
                    "sortOrder": 0
                }
            ],
            "assetTypes": [],
            "flags": 49
        }'
        request=$(echo "$request" | tr -d '\n' | tr -d ' ')

        local api_version="7.2-preview.1"
        local url="https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery?api-version=$api_version"
        local response=$(curl -s -X POST "$url" -H "Content-Type: application/json" -d $request)
        if [[ -z $response ]]; then
            error "Failed to connect to Visual Studio Marketplace API."
            trace "VSCode Extension" "$EXTENSION"
            trace "Pre-Release" "$PRE_RELEASE"
            return 1
        fi
        response=$(echo "$response" | tr -d '\n')

        # Extract the latest version of the vscode extension
        #cleaned_response=$(echo "$response" | grep -oP '"(key|version|value)":\s*"[^"]+"')
        cleaned_response=$(echo "$response" | awk -F '"' '/"(key|version|value)":/ {for(i=2; i<NF; i+=2) if ($i ~ /^(key|version|value)$/) print "\"" $i "\": \"" $(i+2) "\""}')
        filtered_response=$(echo "$cleaned_response" | awk '
        /"version":/ {gsub(/^"version":\s*"|"$/, "", $0); print $0; next} 
        /"key":/ {key=$0; gsub(/^"key":\s*"|"$/, "", key)} 
        /"value":/ && key ~ /Microsoft\.VisualStudio\.Code\.PreRelease/ {
        value=$0; gsub(/^"value":\s*"|"$/, "", value); 
        if (value == "true") {print "-pre"}; 
        next
        } 
        {next}
        ')
        local versions="${filtered_response//$'\n'-pre/-pre}"
        local latest_stable=$(echo "$versions" | grep -v -- "-pre" | head -n 1)
        local latest_prerelease=$(echo "$versions" | grep -- "-pre" | head -n 1)
        latest_prerelease=${latest_prerelease%-pre}
        
        # Output the latest version of the vscode extension based on pre-release flag
        if [ "$PRE_RELEASE" == 1 ]; then
            if [ -z "$latest_prerelease" ]; then
                error "Failed to get the latest pre-release version of vscode extension '$EXTENSION'."
                trace "Known Versions" versions
                return 1
            fi
            echo "$latest_prerelease"
        else
            if [ -z "$latest_stable" ]; then
                error "Failed to get the latest stable version of vscode extension '$EXTENSION'."
                trace "Known Versions" versions
                return 1
            fi
            echo "$latest_stable"
        fi
        return 0
    fi

    error "Unsupported vscode marketplace '$VSCODE_MARKET'."
    return 1
}

# List all installed vscode extensions and check for update if need
function vscode_list()
{
    # Usage with correct arguments as inputs
    if [ $# -gt 1 ] || ! check_flag "--available" "$1"; then
        usage "Usage: ${FUNCNAME[0]} [--available]"
        usage "- available: optional flag to filter available updates of installed extensions."
        return 1
    fi
    AVAILABLE=$1

    # Check if vscode is ready
    vscode_ready || return 1

    # List all installed extensions with versions
    local -A installed_extensions
    local output extension_id installed_version
    output=$(shell_exec "cmd" "$VSCODE_BINPATH --list-extensions --show-versions")
    if [ $? -ne 0 ]; then
        error "Failed to list installed extensions."
        return 1
    fi
    while IFS='@' read -r extension_id installed_version; do
        installed_extensions["$extension_id"]="$installed_version"
    done <<< "$output"
    trace "VSCode Extension (Installed)" installed_extensions  

    # Output all installed vscode extensions if no marketplace is provided
    if [ -z "$AVAILABLE" ]; then
        echo "${!installed_extensions[@]}"
        return 0
    fi

    # Check for update of installed extensions from the marketplace
    local latest_version
    local -a available_extensions
    for extension_id in "${!installed_extensions[@]}"; do
        trace "Detecting latest verion of VSCode Extension '$extension_id'..."
        latest_version=$(vscode_latest "$extension_id")
        if [ $? -ne 0 ]; then
            warn "Failed to get the latest version of vscode extension '$extension_id'."
            continue
        fi

        installed_version="${installed_extensions[$extension_id]}"
        if [ "$installed_version" != "$latest_version" ]; then
            trace "VSCode Extension Version ('$extension_id'): Latest='$latest_version', Installed='$installed_version'"
            available_extensions+=("$extension_id")
        fi
        trace "Detecting latest verion of VSCode Extension '$extension_id'... Done!"
    done
    trace "VSCode Extension (Available)" available_extensions
    echo "${available_extensions[@]}"
    return 0
}

# Install the vscode extensions
function vscode_extend()
{
    # Usage with correct arguments as inputs
    if [ $# -lt 1 ]; then
        usage "Usage: ${FUNCNAME[0]} {<publisher>.<extension>}..."
        usage "- <publisher>: The name of the publisher of vscode extension."
        usage "- <extension>: The name of the vscode extension."
        return 1
    fi

    # Check if vscode is ready
    vscode_ready || return 1

    # Try to install each vscode extension in the list
    local -a failed_extensions
    for item in "$@"; do

        # If extension is followed by '!', mark it as "--force" (maybe extension updating)
        local extension="$item"
        local force=""
        if [[ "$extension" == *'!' ]]; then
            extension="${extension%?}"
            force="--force"
        fi

        # Remove '?' in the end of extension.
        if [[ "$extension" == *'?' ]]; then
            extension="${extension%?}"
        fi

        # Skip invalid vscode extensions
        if ! [[ "$extension" =~ ^[a-z0-9-]+\.[a-z0-9-]+$ ]]; then
            error "Unrecognized format of vscode extension '$item'."
            failed_extensions+=("$item")
            continue
        fi

        # Install the vscode extension
        if ! shell_exec "cmd" "$VSCODE_BINPATH --install-extension $extension $force"; then
            error "Failed to install vscode extension '$item'."
            failed_extensions+=("$item")
        fi
    done

    # Output the failed extensions if any
    if [ ${#failed_extensions[@]} -gt 0 ]; then
        error "Failed to install the following vscode extensions: ${failed_extensions[@]}."
        return 1
    fi
    return 0;
}

# Install or update the vscode extensions from the list
function vscode_extensions()
{
    # Usage with correct arguments as inputs
    if [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <filename>"
        usage "- <filename>: The .cfg file contains the list of extensions to install or update."
        return 1
    fi

    # Check if vscode is ready
    vscode_ready || return 1

    # Load the list of extensions
    local output
    local -a extensions
    output=$(load_cfg "$1" | tr -d '\n') || return 1
    IFS=$' ' read -r -a extensions <<< "$output"
    if [ ${#extensions[@]} -eq 0 ]; then
        warn "No extensions found in the config file."
        return 0
    fi
    trace "VSCode Extension (Required)" extensions

    # Get the list of installed extensions
    local -a installed_extensions
    output=$(vscode_list) || return 1
    IFS=$' ' read -r -a installed_extensions <<< "$output"
    trace "VSCode Extension (Installed)" installed_extensions

    # Check for missing extensions
    for item in "${extensions[@]}"; do
        if [[ " ${installed_extensions[@]} " =~ " $item " ]]; then
            continue
        fi
        missing+=("$item")
    done

    # Install missing extensions if any
    local -a missing_extensions
    if [ ${#missing_extensions[@]} -gt 0 ]; then
        trace "VSCode Extension (Missing)" missing_extensions
        vscode_extend "${missing_extensions[@]}" || return 1
        echo "All missing vscode extensions are installed."
    else
        echo "All required vscode extensions are already installed."
    fi

    # Fetch the available updates for installed extensions
    local -a available_extensions
    output=$(vscode_list --available) || return 1
    IFS=$' ' read -r -a available_extensions <<< "$output"
    if [ ${#available_extensions[@]} -eq 0 ]; then
        echo "All installed vscode extensions are up-to-date."
        return 0
    fi

    # Overlap the required extensions with the available updates
    local -a updated_extensions
    mapfile -t updated_extensions < <(comm -12 \
        <(printf "%s\n" "${extensions[@]}" | tr '[:upper:]' '[:lower:]' | sort) \
        <(printf "%s\n" "${available_extensions[@]}" | tr '[:upper:]' '[:lower:]' | sort))
    if [ ${#updated_extensions[@]} -eq 0 ]; then
        echo "All required vscode extensions are up-to-date."
        return 0
    fi
    trace "VSCode Extension (Updated)" updated_extensions

    # Install the available updates for required extensions
    vscode_extend "${updated_extensions[@]/%/!}" || return 1
    return 0
}
