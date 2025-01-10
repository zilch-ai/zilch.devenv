#!/bin/bash

# Check if reentry itself is already loaded
if [[ -n "${__REENTRY_SH_LOADED__}" ]]; then
    return
fi
export __REENTRY_SH_LOADED__=1

# Reentry function to prevent duplicated source of the same script
function reentry()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ] || ([ -n "$2" ] && [ "$2" -ne 0 ] && [ "$2" -ne 1 ]); then
        echo "Usage: $0 <script> [<trace>]"
        echo "- <script>: The bash script file."
        echo "- <trace>: Optional trace flag. Set to 1 to enable trace mode. Default is 0."
        return 1
    fi
    local DEBUG=${2:-0}

    # Normalize the script id base on the script name
    local SCRIPT
    SCRIPT=$(basename "$(realpath "$1")")
    SCRIPT="${SCRIPT//[^a-zA-Z0-9]/_}"
    SCRIPT="${SCRIPT^^}"
    SCRIPT="__${SCRIPT}_LOADED__"

    # Skip with error code if the script is already loaded.
    if [[ -n "${!SCRIPT}" ]]; then
        if [[ "$DEBUG" -eq 1 ]]; then
            echo "[DEBUG] Skip loading script '$1' as it is already loaded."
        fi
        return 1
    fi

    # Mark the script as loaded as success
    export "$SCRIPT"=1
    if [[ "$DEBUG" -eq 1 ]]; then
        echo "[DEBUG] Loading script '$1'..."
    fi
    return 0
}
