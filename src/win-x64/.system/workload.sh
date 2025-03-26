#!/bin/bash

# Check if the script is being sourced
source "$LAUNCH_ROOT/.system/reentry.sh"
reentry "${BASH_SOURCE[0]}" || return 0

source "$LAUNCH_ROOT/.system/volta.sh"

function workload_cn()
{

}
function workload_markdown()
{

}

function workload_rust()
{

}

function workload_csharp()
{

}

function workload_python()
{

}

function workload_typescript()
{

}
