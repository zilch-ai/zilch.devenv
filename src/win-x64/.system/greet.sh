#!/bin/bash

# Find the proper locale file if available
function find_locale_file()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        echo "Usage: $0 <filename> [<locale>]"
        echo "- <filename>: The original file name."
        echo "- <locale>: The optional locale to find the file with the same naming pattern."
        return 1
    fi

    local FILE="$1"
    local DIR=$(dirname "$FILE")
    local LOCALE="${2:-}"

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

    # Standardize the locale format (RFC 5646, language-REGION)
    # - Replace underscores with hyphens (if necessary)
    # - Convert first 2 characters to lowercase (language) and last 2 characters to uppercase (REGION)
    # - Add missing separator '-' between language and REGION if need
    LOCALE="${LOCALE//_/-}"
    LOCALE=$(echo "$LOCALE" | sed -E 's/^([a-z]{2})-([a-z]{2})$/\L\1-\U\2/')
    if ! [[ "$LOCALE" =~ ^[a-z]{2}-[A-Z]{2}$ ]]; then
        echo "Error: Invalid locale format '$LOCALE'."
        return 1
    fi

    # Check if locale file exists and is readable
    local LOCALE_FILE="$DIR/$(basename "$FILE" .${FILE##*.}).$LOCALE.${FILE##*.}"
    if [ ! -r "$LOCALE_FILE" ]; then
        echo "$FILE"
        return 0
    fi
    echo "$LOCALE_FILE"
}

# Prompt for start of the day
function prompt()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        echo "Usage: $0 <filename>"
        echo "- <filename>: The file containing the list of prompts separated by '---'."
        return 1
    fi

    # Check if the file exists and is readable
    local PROMPT="$1"
    if [ ! -r "$PROMPT" ]; then
        echo "Error: File '$PROMPT' not found or is not readable."
        return 1
    fi
    PROMPT=$(find_locale_file "$PROMPT")
    
    # Load all records from the prompt file
    local records=()
    local record=""
    local line
    while IFS= read -r line; do
        line="${line%$'\r'}"
        if [[ "$line" == "---" ]]; then
            if [[ -n "$record" ]]; then
                records+=("$record")
                record=""
            fi
        else
            record+="$line"
        fi
    done < "$PROMPT"
    if [[ -n "$record" ]]; then
        records+=("$record")
    fi

    # Check if any records were loaded
    if [[ ${#records[@]} -eq 0 ]]; then
        echo "Error: No prompts found in the file."
        return 1
    fi

    # Display a random prompt
    local random=$((RANDOM % ${#records[@]}))
    echo -e "${records[$random]}"
    return 0
}

# Countdown with prompt for key press
function countdown()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        echo "Usage: $0 <template> [<duration>] [<timeout>]" >&2
        echo "- <template>: A message template containing {{COUNTDOWN}} as the countdown placeholder." >&2
        echo "- <duration>: The optional countdown duration in seconds (positive integer, default:5)." >&2
        echo "- <timeout>: The optional exit code for timeout (0/1, default:1)." >&2
        echo "Function returns one of the following codes (0/1/2):" >&2
        echo "- 2: Error" >&2
        echo "- 1: ESC is pressed" >&2
        echo "- 0: if any other key is pressed" >&2
        echo "- <timeout>: if countdown expires" >&2
        return 2
    fi

    # Verify input parameters
    local TEMPLATE="$1"
    local COUNTDOWN="${2:-5}"
    local TIMEOUT="${3:-1}"
    if ! [[ $COUNTDOWN =~ ^[0-9]+$ ]] || [ $COUNTDOWN -le 0 ]; then
        echo "Error: Countdown duration must be a positive integer." >&2
        return 2
    fi
    if [ $TIMEOUT -ne 0 ] && [ $TIMEOUT -ne 1 ]; then
        echo "Error: Exit code for timeout must be 0 or 1." >&2
        return 2
    fi

    # Start the countdown
    local prompt
    local key
    local pressed
    while [ $COUNTDOWN -gt 0 ]; do
        prompt=$(echo "$TEMPLATE" | sed "s/{{COUNTDOWN}}/$COUNTDOWN/g")
        echo -ne "\r$prompt"

        stty -echo
        read -t 1 -n 1 key
        pressed=$?
        stty echo

        if [ $pressed -eq 0 ]; then
            if [[ $key == $'\e' ]]; then
                return 1
            else
                return 0
            fi
        fi

        COUNTDOWN=$((COUNTDOWN - 1))
    done
    return $TIMEOUT
}
