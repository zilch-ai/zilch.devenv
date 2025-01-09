#!/bin/bash

# Prompt for start of the day
function prompt()
{
    # Check usage with correct arguments as inputs
    if [ -z "$1" ]; then
        echo "Usage: $0 <filename>"
        echo "- <filename>: The file containing the list of prompts separated by '---'."
        return 1
    fi

    local PROMPT="$1"
    if [ ! -f "$PROMPT" ]; then
        echo "Error: File '$PROMPT' not found or is not readable."
        return 1
    fi

    local records=()
    local record=""
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if [[ -n "$record" ]]; then
                records+=("$record")
                record=""
            fi
        else
            record+="$line"$'\n'
        fi
    done < "$PROMPT"
    if [[ -n "$record" ]]; then
        records+=("$record")
    fi

    if [[ ${#records[@]} -gt 0 ]]; then
        random=$((RANDOM % ${#records[@]}))
        echo -e "${records[$random]}"
    fi
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
