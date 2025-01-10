#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

# Load the .cfg file
function load_cfg()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        echo "Usage: $0 <filename>"
        echo "- <filename>: The .cfg configuration file contains the list of items."
        return 1
    fi

    # Check if the file exists and is readable
    CONFIG=$(readlink -f "$1")
    if [ ! -r "$CONFIG" ]; then
        echo "Error: File '$CONFIG' not found or is not readable."
        return 1
    fi

    # Read the config file
    list=()
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^# ]]; then
          continue
        fi

        # Extra the cleaned line item (no comments and extra spaces)
        item=$(echo "$line" | sed 's/#.*//' | xargs | sed 's/\r//' )
        if [ -z "$item" ]; then
          continue
        fi

        # Add the item to the list
        list+=("$item")
    done < "$CONFIG"

    # Dump the list as output
    echo -n "${list[@]}"
    return 0
}

# Load a .conf file and cleanup comments and other ignorables
function load_conf()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        echo "Usage: $0 <filename>"
        echo "- <filename>: The .conf configuration file contains the list of key-value pairs."
        return 1
    fi

    # Check if the file exists and is readable
    local CONF="$1"
    if [ ! -r "$CONF" ]; then
        echo "Error: File '$CONF' not found or is not readable."
        return 1
    fi

    # Clean the .conf file:
    # - Remove comments (# or ;) from lines
    # - Remove inline comments (after '=' sign) and trim trailing spaces
    # - Remove empty lines
    # NOTE: Please protect quoted values not to be cleaned up
    local cleaned
    cleaned=$(awk '
    BEGIN {
        in_double_quote = 0
        in_single_quote = 0
        escaped = 0
    }
    {
        # Loop through each character in the line
        for (i = 1; i <= length($0); i++) {
            char = substr($0, i, 1)
            prev_char = substr($0, i - 1, 1)

            # Handle escaped characters
            if (prev_char == "\\") {
                escaped = 1
            } else {
                escaped = 0
            }

            # Toggle quote flags if not escaped
            if (!escaped) {
                if (char == "\"" && !in_single_quote) {
                    in_double_quote = !in_double_quote
                }
                if (char == "'"'"'" && !in_double_quote) {
                    in_single_quote = !in_single_quote
                }
            }

            # If outside quotes and encountering a comment character, truncate the line
            if (!in_double_quote && !in_single_quote && (char == "#" || char == ";")) {
                $0 = substr($0, 1, i - 1)
                break
            }
        }
        # Trim trailing spaces
        gsub(/^[[:blank:]]+|[[:blank:]]+$/, "")
        # Print the line if it is not empty or if it is inside quotes
        if ($0 != "" || in_double_quote || in_single_quote) {
            print
        }
    }' "$CONF")
    echo "$cleaned"
    return 0
}

# Extract value (or values) of a key in a .conf file
function extract_conf()
{
    echo "TODO"
    return 0
}