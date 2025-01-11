#!/bin/bash

# Check if reentry itself is already loaded
if [[ -n "${__REENTRY_SH_LOADED__}" ]]; then
    return
fi
export __REENTRY_SH_LOADED__=1

# Enable debug mode if set to 1
DEBUG=${DEBUG:-0}

# Output usage message to stderr
function usage()
{
    echo "$*" >&2
}

# Output error message to stderr
function error()
{
    echo "[Error] $*" >&2
}

# Output error message to stderr
function Warn()
{
    echo "[Warning] $*" >&2
}

# Output trace message to stderr if debug mode is enabled
function trace()
{
    # Check usage with correct arguments as inputs
    if [[ $# -gt 2 ]]; then
        usage "Usage: trace [<prompt>] <message>"
        usage "- <prompt>: The optional leading prompt of the trace message."
        usage "- <message>: The message, list, or key-value pairs to be traced."
        return 1
    fi

    # Skip if debug mode is disabled or no message is provided
    if [[ $DEBUG -eq 0 ]] || [[ $# -eq 0 ]]; then
        return 0
    fi

    # Trace the message directly if no prompt is provided
    if [[ $# -eq 1 ]]; then
        printf "[DEBUG] %s\n" "$1" >&2
        return 0
    fi

    # Declare the prompt and message as local variables
    local PROMPT="$1"
    local MESSAGE="$2"

    # Trace the list with prompt
    if [[ "$(declare -p MESSAGE 2>/dev/null)" =~ "declare -a" ]]; then
        for i in "${!MESSAGE[@]}"; do
            printf "[DEBUG] %s[%d]: '%s', Length=%d\n" "$PROMPT" "$i" "${MESSAGE[$i]}" "${#MESSAGE[$i]}" >&2
        done
        return 0
    fi

    # Trace the key-value pairs with prompt
    if [[ "$(declare -p MESSAGE 2>/dev/null)" =~ "declare -A" ]]; then
        for key in "${!MESSAGE[@]}"; do
            printf "[DEBUG] %s[%s]: %s, Length=%d\n" "$PROMPT" "$key" "${MESSAGE[$key]}" "${#MESSAGE[$key]}" >&2
        done
        return 0
    fi

    # Trace the string with prompt
    printf "[DEBUG] %s: '%s', Length=%d\n" "$PROMPT" "$MESSAGE" "${#MESSAGE}" >&2
    return 0
}

# Reentry function to prevent duplicated source of the same script
function reentry()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ] || ([ -n "$2" ] && [ "$2" -ne 0 ] && [ "$2" -ne 1 ]); then
        error "Usage: $0 <script>"
        error "- <script>: The bash script file."
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
        trace "Skip loading script '$1' as it is already loaded."
        return 1
    fi

    # Mark the script as loaded as success
    export "$SCRIPT"=1
    trace "Loading script '$1'..."
    return 0
}
