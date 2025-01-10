#!/bin/bash

function load_cfg()
{
  # Check usage with correct number of arguments
  if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    return 1
  fi

  # Check if the file exists and is readable
  CONFIG=$(readlink -f "$1")
  if [ ! -f "$CONFIG" ]; then
    echo "Error: File '$CONFIG' not found."
    return 1
  fi
  if [ ! -r "$CONFIG" ]; then
    echo "Error: Cannot read file '$CONFIG'."
    return 1
  fi

  # Read the config file
  list=()
  while IFS= read -r line; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      continue
    fi

    # Extra the cleaned line item (no comments and extra spaces)
    item=$(echo "$line" | sed 's/#.*//' | xargs | sed 's/\r//' )
    if [ -z "$item" ]; then
      continue
    fi

    # Add the item to the list
    list+=("$item")
  done < "$CONFIG"

  # Dump the list as output
  echo -n "${list[@]}"
  return 0
}