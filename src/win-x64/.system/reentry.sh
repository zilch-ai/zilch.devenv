#!/bin/bash

# Check if reentry itself is already loaded
if [[ -n "${__REENTRY_SH_LOADED__}" ]]; then
    return
fi
export __REENTRY_SH_LOADED__=1

# Enable debug mode if set to 1
DEBUG=${DEBUG:-0}

# Output trace message to stderr if debug mode is enabled
function trace()
{
    # Check usage with correct arguments as inputs
    if [[ $# -gt 2 ]]; then
        usage "Usage: ${FUNCNAME[0]} [<prompt>] <message>"
        usage "- <prompt>: The optional leading prompt of the trace message."
        usage "- <message>: The message, list, or map (key-value pairs) to be traced."
        usage "Examples:"
        usage "- Example(text): trace \"A simple debug message\""
        usage "- Example(text with prompt): trace \"MyPrompt\" \"A simple debug message\""
        usage "- Example(list with prompt): trace \"ListPrompt\" myList"
        usage "- Example(map with prompt): trace \"MapPrompt\" myMap"
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

    # Skip if the message is empty
    local PROMPT="$1"
    if [[ -z "$2" ]]; then
        printf "[DEBUG] %s: '' (Empty)\n" "$PROMPT" >&2
        return 0
    fi

    # Trace the list with prompt
    if [[ "$(declare -p $2 2>/dev/null)" =~ "declare -a" ]]; then
        local -n ARRAY_REF="$2"
        for i in "${!ARRAY_REF[@]}"; do
            printf "[DEBUG] %s: #%d -> '%s', Length=%d\n" "$PROMPT" "$i" "${ARRAY_REF[$i]}" "${#ARRAY_REF[$i]}" >&2
        done
        return 0
    fi

    # Trace the map (key-value pairs) with prompt
    if [[ "$(declare -p $2 2>/dev/null)" =~ "declare -A" ]]; then
        local -n MAP_REF="$2"
        for key in "${!MAP_REF[@]}"; do
            printf "[DEBUG] %s: '%s' -> '%s', Length=%d\n" "$PROMPT" "$key" "${MAP_REF[$key]}" "${#MAP_REF[$key]}" >&2
        done
        return 0
    fi

    # Trace the string with prompt
    local MESSAGE="$2"
    printf "[DEBUG] %s: '%s', Length=%d\n" "$PROMPT" "$MESSAGE" "${#MESSAGE}" >&2
    return 0
}

# Output error message to stderr
function warn()
{
    echo "[WARNING] $*" >&2
}

# Output error message to stderr
function error()
{
    echo "[ERROR] $*" >&2
}

# Output usage message to stderr
function usage()
{
    echo "$*" >&2
}

# Reentry function to prevent duplicated source of the same script
function reentry()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ] || ([ -n "$2" ] && [ "$2" -ne 0 ] && [ "$2" -ne 1 ]); then
        error "Usage: ${FUNCNAME[0]} <script>"
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

# Check if flag parameter was set correctly
function check_flag()
{
    # Check usage with correct arguments as inputs
    if [[ $# -gt 2 ]] || [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <flag> [<actual>]"
        usage "- <expected>: The expected flag value."
        usage "- <actual>: The actual flag value (optional)."
        return 1
    fi
    local flag=$(echo "$1" | xargs)
    local actual=$(echo "$2" | xargs)

    # Return success if no flag is set
    if [ -z "$actual" ]; then
        return 0
    fi

    # Check if the actual flag is set and matches the expected flag
    if [[ "$flag" != "$actual" ]]; then
        trace "Flag argument mismatch."
        trace "Expected Flag" "$flag"
        trace "Actual Flag" "$actual"
        return 1
    fi
    return 0
}

# Verify enum parameter
function check_enum()
{
    # Check usage with correct arguments as inputs
    if [[ $# -gt 2 ]] || [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <enum|enum!> [<actual>]"
        usage "- <enum>: The list of predefined enum values, separated by '|'."
        usage "- <actual>: The actual enum value (optional as default)."
        usage "Note: If the <enum> followed by '!', empty value is not allowed."
        return 1
    fi

    # Check if the enum value ends with '!', indicating that empty value is not allowed
    local predefined="$1"
    local actual="$2"
    if [[ "$predefined" =~ !$ ]] && [ -z "$actual" ]; then
        error "Actual enum value cannot be empty when enum is followed by '!'."
        return 1
    fi
    predefined="${predefined%!}"
    predefined="${predefined//|/ }"

    # Return success if no actual value is set and it's valid for optional cases
    if [ -z "$actual" ]; then
        return 0
    fi
    
    # Check if the actual value is within the list of predefined enum values
    if ! echo "$predefined" | grep -qw "$actual"; then
        trace "Enum argument mismatch."
        trace "Predefined Enum" "$predefined"
        trace "Actual Enum" "$actual"
        return 1
    fi
    return 0
}
