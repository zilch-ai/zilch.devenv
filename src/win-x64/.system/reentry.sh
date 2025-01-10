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
    if [ -z "$1" ]; then
        echo "Usage: $0 <script>"
        echo "- <script>: The bash script file."
        return 1
    fi

    # Normalize the script id base on the script name
    local SCRIPT
    SCRIPT=$(basename "$(realpath "$1")")
    SCRIPT="${SCRIPT//[^a-zA-Z0-9]/_}"
    SCRIPT="${SCRIPT^^}"
    SCRIPT="__${SCRIPT}_LOADED__"

    # Skip with error code if the script is already loaded.
    if [[ -n "${!SCRIPT}" ]]; then
        return 1
    fi

    # Mark the script as loaded as success
    export "$SCRIPT"=1
    return 0
}
