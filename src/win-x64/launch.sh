#!/bin/bash
ROOT=$(cd "$(dirname "$0")" && pwd)

# Welcome
echo "Hi, [32m$(whoami)@$(hostname)[0m."
WELCOME="$ROOT/.data/welcome.txt"
if [ -f "$WELCOME" ]; then
    # Welcome ASCII Art
    echo
    echo -e "[33m$(cat "$WELCOME")[0m"
fi
PROMPT="$ROOT/.data/prompt.txt"
if [ -f "$PROMPT" ]; then
    # Prompt of the day
    echo
    source "$ROOT/.system/prompt.sh" "$PROMPT" 32
fi

# Countdown with prompt to skip updating dev environment
SKIPPED=""
COUNTDOWN=5
while [ $COUNTDOWN -gt 0 ]; do
    echo -ne "\rPreparing to update your development environment in $COUNTDOWN seconds... Press any key to skip. "
    read -t 1 -n 1 key
    if [ $? -eq 0 ] || [ -n "$key" ]; then
        SKIPPED="Y"
        break
    fi
    COUNTDOWN=$((COUNTDOWN - 1))
done

# Update development environment if not skipped
if [ -z "$SKIPPED" ]; then
    echo "Proceeding with development environment update..."
    source "$ROOT/.system/scoop.sh"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update development environment using scoop."
        exit 1
    fi
else
    echo "Development environment update skipped by user."
fi
