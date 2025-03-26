#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

# Dependencies (sub modules)
source ./.system/config.sh
source ./.system/shell.sh

function volta_install()
{

}

function volta_list()
{

}

functiom volta_