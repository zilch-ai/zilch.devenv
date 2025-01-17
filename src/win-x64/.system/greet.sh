#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

# Say hi to the user with a custom message
function sayhi()
{
    # Check usage with correct arguments as inputs
    if [ $# -gt 1 ]; then
        echo "Usage: sayhi [template]"
        return 0
    fi

    # If no arguments are provided, say hi to the user
    if [ -z "$1" ]; then
        echo "Hi, $(whoami)@$(hostname)."
        return 0
    fi

    # Check if the file exists and is readable
    if [ ! -r "$1" ]; then
        echo "Welcome template file '$1' not found or is not readable."
        return 1
    fi

    # Evaluate the template and display the message
    local template=$(<$1)
    local command='
        echo "'"$template"'"
    '
    local content=$(bash -c "$command")
    echo "$content"
}

# Prompt for start of the day
function prompt()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        usage "Usage: ${FUNCNAME[0]} <filename>"
        usage "- <filename>: The file containing the list of prompts separated by '---'."
        return 1
    fi

    # Check if the file exists and is readable
    local PROMPT="$1"
    if [ ! -r "$PROMPT" ]; then
        error "File '$PROMPT' not found or is not readable."
        return 1
    fi

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
            record+="$line\n"
        fi
    done < "$PROMPT"
    if [[ -n "$record" ]]; then
        records+=("$record")
    fi

    # Check if any records were loaded
    if [[ ${#records[@]} -eq 0 ]]; then
        error "No prompts found in the file."
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
        usage "Usage: ${FUNCNAME[0]} <template> [<duration>] [<timeout>]"
        usage "- <template>: A message template containing {{COUNTDOWN}} as the countdown placeholder."
        usage "- <duration>: The optional countdown duration in seconds (positive integer, default:5)."
        usage "- <timeout>: The optional exit code for timeout (0/1, default:1)."
        usage "Function returns one of the following codes (0/1/2):"
        usage "- 2: Error"
        usage "- 1: ESC is pressed"
        usage "- 0: if any other key is pressed"
        usage "- <timeout>: if countdown expires"
        return 2
    fi

    # Verify input parameters
    local TEMPLATE="$1"
    local COUNTDOWN="${2:-5}"
    local TIMEOUT="${3:-1}"
    if ! [[ $COUNTDOWN =~ ^[0-9]+$ ]] || [ $COUNTDOWN -le 0 ]; then
        error "Countdown duration must be a positive integer."
        return 2
    fi
    if [ $TIMEOUT -ne 0 ] && [ $TIMEOUT -ne 1 ]; then
        error "Exit code for timeout must be 0 or 1."
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
