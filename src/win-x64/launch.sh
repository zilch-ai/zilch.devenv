#!/bin/bash
ROOT=$(cd "$(dirname "$0")" && pwd)

# Try to focus on the current terminal window
# powershell.exe -File ".system/focus.ps1"

# Greetings
source "$ROOT/.system/greet.sh"
echo "Hi, [32m$(whoami)@$(hostname)[0m."
WELCOME="$ROOT/.data/welcome.txt"
if [ -f "$WELCOME" ]; then
    echo -e "[33m$(cat "$WELCOME")[0m"
fi
PROMPT="$ROOT/.data/prompt.txt"
if [ -f "$PROMPT" ]; then
    echo -e "[32m$(prompt "$PROMPT")\n[0m"
fi

# Countdown before updating development environment
powershell.exe -File ".system/focus.ps1"
countdown "Dev environment updating will start in {{COUNTDOWN}}s. Press ESC to skip or any other key to run immediately..." 5 0
case $? in
    2)
        echo
        echo "Error: Failed to start the countdown."
        exit 1
        ;;
    1)
        echo
        echo "Development environment update skipped by user."
        exit 0
        ;;
    0)
        echo
        echo "Proceeding with development environment update..."
        ;;
esac

# Update scoop, buckets and built-in apps
source "$ROOT/.system/scoop.sh"
scoop_self \
&& scoop_buckets "$ROOT/.data/scoop-buckets.csv" \
&& scoop_apps "$ROOT/.data/scoop-apps.cfg" \
&& scoop_all \
|| (echo "Error: Failed to update development environment." && exit 1)

# Pause before continue
read -p "[DEBUG] Press any key to continue..."
