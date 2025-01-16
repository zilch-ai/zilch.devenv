#!/bin/bash
LAUNCH_ROOT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# Trace the bash version and shell path
source "$LAUNCH_ROOT/.system/reentry.sh"
#trace "Bash '$BASH_VERSION' is running from '$SHELL'."

# Load .conf file and extract debug flage and locale settings
source "$LAUNCH_ROOT/.system/config.sh"
SETTINGS=$(load_conf "$LAUNCH_ROOT/launch.conf") || { error "Failed to load the 'launch.conf' file."; exit 1; }
DEBUG=$(extract_conf "$SETTINGS" "debug")
LOCALE=$(extract_conf "$SETTINGS" "locale")

# Greetings
source "$LAUNCH_ROOT/.system/greet.sh"
echo "Hi, [32m$(whoami)@$(hostname)[0m."
WELCOME="$LAUNCH_ROOT/.data/welcome.txt"
if [ -f "$WELCOME" ]; then
    echo -e "[33m$(cat "$WELCOME")[0m"
fi
PROMPT="$LAUNCH_ROOT/.data/prompt.txt"
if [ -f "$PROMPT" ]; then
    PROMPT=$(with_locale "$PROMPT" "$LOCALE")
    echo -e "[32m$(prompt "$PROMPT")\n[0m"
fi

# Countdown before updating development environment
powershell.exe -File ".system/focus.ps1"
COUNTDOWN=$(extract_conf "$SETTINGS" "countdown")
countdown "Dev environment updating will start in {{COUNTDOWN}}s. Press ESC to skip or any other key to run immediately..." $COUNTDOWN 0
case $? in
    2)
        echo
        error "Failed to start the countdown."
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
source "$LAUNCH_ROOT/.system/scoop.sh"
scoop_ready || exit 1 # Check if scoop is installed
scoop_update || exit 1 # Update scoop itself
scoop_buckets "$LAUNCH_ROOT/.data/scoop-buckets.csv" || exit 1
scoop_apps "$LAUNCH_ROOT/.data/scoop-apps.cfg" || exit 1
scoop_update "--all" || exit 1 # Update all installed scoop apps

# Update vscode and its extensions
source "$LAUNCH_ROOT/.system/vscode.sh"
vscode_default "vscode" "code" || exit 1
vscode_extensions "$LAUNCH_ROOT/.data/vscode-exts.cfg" || exit 1

# Pause before continue
read -p "[DEBUG] Press any key to continue..."
