#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

# Find the proper locale file if available
function with_locale()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        usage "Usage: $0 <filename> [<locale>]"
        usage "- <filename>: The original file name."
        usage "- <locale>: The optional locale in RFC 5646 format (language-REGION)."
        return 1
    fi

    local FILE="$1"
    local DIR=$(dirname "$FILE")
    local LOCALE="${2:-}"
    trace "Locale(Input)" "$LOCALE"

    # Detect locale if not set
    if [ -z "$LOCALE" ]; then
        LOCALE=$(cat "$DIR/.LOCALE" 2>/dev/null)
    fi
    if [ -z "$LOCALE" ]; then
        LOCALE=$(locale | grep "LC_MESSAGES" | cut -d'=' -f2)
    fi
    if [ -z "$LOCALE" ]; then
        echo $FILE
        return 0
    fi
    trace "Locale(Detected)" "$LOCALE"

    # Standardize the locale format (RFC 5646, language-REGION)
    # - Trim leading/trailing whitespaces
    # - Replace underscores with hyphens (if necessary)
    # - Convert first 2 characters to lowercase (language) and last 2 characters to uppercase (REGION)
    # - Add missing separator '-' between language and REGION if need
    LOCALE="${LOCALE#"${LOCALE%%[![:space:]]*}"}"
    LOCALE="${LOCALE%"${LOCALE##*[![:space:]]}"}"
    LOCALE="${LOCALE//_/-}"
    LOCALE=$(echo "$LOCALE" | sed -E 's/^([a-z]{2})-([a-z]{2})$/\L\1-\U\2/')
    if ! [[ "$LOCALE" =~ ^[a-z]{2}-[A-Z]{2}$ ]]; then
        error "Invalid locale format '$LOCALE'."
        return 1
    fi
    trace "Locale(Normalized)" "$LOCALE"

    # Fallback to default if locale is 'en-US'
    if [[ "$LOCALE" == "en-US" ]]; then
        trace "Fallback to '$FILE'."
        echo $FILE
        return 0
    fi

    # Check if locale file exists and is readable
    local LOCALE_FILE="$DIR/$(basename "$FILE" .${FILE##*.}).$LOCALE.${FILE##*.}"
    if [ ! -r "$LOCALE_FILE" ]; then
        trace "Fallback to '$FILE'."
        echo "$FILE"
        return 0
    fi

    # Return the locale file if found
    trace "Fallback to '$LOCALE_FILE'."
    echo "$LOCALE_FILE"
}

# Load the .cfg file
function load_cfg()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        usage "Usage: $0 <filename>"
        usage "- <filename>: The .cfg configuration file contains the list of items."
        return 1
    fi

    # Check if the file exists and is readable
    CONFIG=$(readlink -f "$1")
    if [ ! -r "$CONFIG" ]; then
        error "Error: File '$CONFIG' not found or is not readable."
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
        usage "Usage: $0 <filename>"
        usage "- <filename>: The .conf configuration file contains the list of key-value pairs."
        return 1
    fi

    # Check if the file exists and is readable
    local CONF="$1"
    if [ ! -r "$CONF" ]; then
        error "Error: File '$CONF' not found or is not readable."
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
        for (i = 1; i <= length($0); i++)
        {
            char = substr($0, i, 1)
            prev_char = substr($0, i - 1, 1)

            # Handle escaped characters
            if (prev_char == "\\")
            {
                escaped = 1
            }
            else
            {
                escaped = 0
            }

            # Toggle quote flags if not escaped
            if (!escaped)
            {
                if (char == "\"" && !in_single_quote)
                {
                    in_double_quote = !in_double_quote
                }
                if (char == "'"'"'" && !in_double_quote)
                {
                    in_single_quote = !in_single_quote
                }
            }

            # If outside quotes and encountering a comment character, truncate the line
            if (!in_double_quote && !in_single_quote && (char == "#" || char == ";"))
            {
                $0 = substr($0, 1, i - 1)
                break
            }
        }
        # Trim trailing spaces
        gsub(/^[[:blank:]]+|[[:blank:]]+$/, "")
        # Print the line if it is not empty or if it is inside quotes
        if ($0 != "" || in_double_quote || in_single_quote)
        {
            print
        }
    }' "$CONF")
    echo "$cleaned"
    return 0
}

# Extract value of a key in a .conf file
function extract_conf()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ] || [ -z "$2" ]; then
        usage "Usage: $0 <content> <key>"
        usage "- <content>: The .conf configuration file."
        usage "- <key>: The key whose value needs to be extracted."
        return 1
    fi
    local CONF="$1"
    local KEY="$2"

    # Extract the value for the specified key
    local value
    value=$(echo "$CONF" | awk -F= -v key="$KEY" '
    BEGIN { found = 0 }
    {
        # Trim leading and trailing spaces from the key
        gsub(/^[[:blank:]]+|[[:blank:]]+$/, "", $1)

        # Check if the key matches
        if ($1 == key)
        {
            found = 1

            # Extract the value part
            value = substr($0, index($0, "=") + 1)
            gsub(/^[[:blank:]]+|[[:blank:]]+$/, "", value)

            # Check if the value is quoted
            if (value ~ /^".*"$/)
            {
                # Double-quoted value: remove quotes and parse escape characters
                value = substr(value, 2, length(value) - 2)
                gsub(/\\"/, "\"", value)
                gsub(/\\'\''/, "'\''", value)
                gsub(/\\\\/, "\\", value)
            }
            else if (value ~ /^'\''.*'\''$/)
            {
                # Single-quoted value: remove quotes (no escape character parsing)
                value = substr(value, 2, length(value) - 2)
            }
            else
            {
                # Unquoted value: trim whitespace (including \t, \r, \n)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            }

            print value
            exit
        }
    }') || { echo "Error: Key '$KEY' not found in the configuration file."; return 1; }

    # Return the extracted value
    echo "$value"
    return 0
}
