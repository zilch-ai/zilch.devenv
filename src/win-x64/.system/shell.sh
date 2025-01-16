#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

ALLOWED_SHELLS="cmd|ps"

# Run command in the shell
function shell_exec()
{
    # Check usage with correct arguments as inputs
    if [[ $# -lt 2 ]] || [[ $# -gt 3 ]] || ! check_enum "$ALLOWED_SHELLS" "$1" || ! check_flag "--silent" "$3"; then
        usage "Usage: ${FUNCNAME[0]} <shell> <command> [--silent]"
        usage "- <shell>: The shell to execute the command (allowed:$ALLOWED_SHELLS)."
        usage "- <command>: The command to execute in the shell."
        usage "- [--silent]: Optional flag to suppress output."
        return 1
    fi
    local shell="$1"
    local command="$2"
    local silent="$3"

    # Execute the command with output
    if [ -z "$silent" ]; then
        case "$shell" in
            cmd)
                cmd.exe /c "$command"
                return $?
                ;;
            ps)
                powershell.exe -Command "$command"
                return $?
                ;;
            *)
                error "Invalid shell '$shell'."
                return 1
                ;;
        esac
    fi

    # Execute the shell command silently
    case "$shell" in
        cmd)
            cmd.exe /c "$command >nul 2>&1"
            return $?
            ;;
        ps)
            powershell.exe -Command "$command | Out-Null"
            return $?
            ;;
        *)
            error "Invalid shell '$shell'."
            return 1
            ;;
    esac
}

# Get the binary path of the command in the shell
function shell_binpath()
{
    # Check usage with correct arguments as inputs
    if [[ $# -ne 2 ]] || ! check_enum "$ALLOWED_SHELLS" "$1"; then
        usage "Usage: ${FUNCNAME[0]} <shell> <command>"
        usage "- <shell>: The shell to execute the command (allowed:$ALLOWED_SHELLS)."
        usage "- <command>: The command to execute in the shell."
        return 1
    fi
    local shell="$1"
    local command="$2"

    # Execute the command in specific console
    case "$shell" in
        cmd)
            shell_exec "$shell" "where $command"
            ;;
        ps)
            shell_exec "$shell" "Get-Command $command | Select-Object -ExpandProperty Source"
            ;;
        *)
            error "Invalid shell '$shell'."
            return 1
            ;;
    esac
}

