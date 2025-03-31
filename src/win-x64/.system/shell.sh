#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

ALLOWED_SHELLS="cmd|ps"

# Run command in CMD shell
function cmd_exec()
{
    # Check usage with correct arguments as inputs
    if [[ $# -lt 1 || $# -gt 2 ]] || { [[ $# -eq 2 ]] && ! check_flag "--silent" "$2"; }; then
        usage "Usage: ${FUNCNAME[0]} <command> [--silent]"
        usage "- <command>: The command to execute in the `cmd` shell."
        usage "- [--silent]: Optional flag to suppress output."
        return 1
    fi
    local command="$1"
    local silent="$2"

    # Execute the shell command silently
    if [ -z "$silent" ]; then
        trace "EXEC" "timeout 5s cmd /c \"$command\""
        timeout 5s cmd /c "$command"
    else
        trace "EXEC" "timeout 5s cmd /c \"$command >nul 2>&1\""
        timeout 5s cmd /c "$command >nul 2>&1"
    fi
    return $?
}

# Run command in PS shell
function pwsh_exec()
{
    # Check usage with correct arguments as inputs
    if [[ $# -lt 1 || $# -gt 2 ]] || { [[ $# -eq 2 ]] && ! check_flag "--silent" "$2"; }; then
        usage "Usage: ${FUNCNAME[0]} <command> [--silent]"
        usage "- <command>: The command to execute in the `cmd` shell."
        usage "- [--silent]: Optional flag to suppress output."
        return 1
    fi
    local command="$1"
    local silent="$2"

    # Execute the shell command silently
    if [ -z "$silent" ]; then
        trace "EXEC: pwsh -Command \"$command\""
        pwsh -Command "$command"
    else
        trace "EXEC: pwsh -Command \"$command | Out-Null\""
        pwsh -Command "$command | Out-Null"
    fi
    return $?
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
            cmd_exec "where $command"
            ;;
        ps)
            pwsh_exec "Get-Command '$command' | Select-Object -ExpandProperty Source"
            ;;
        *)
            error "Invalid shell '$shell'."
            return 1
            ;;
    esac
}
