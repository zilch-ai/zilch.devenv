# Check if scoop is installed
if ! command -v scoop &>/dev/null; then
    echo "Error: Scoop is not installed. Please install scoop first."
    exit 1
fi

# Update scoop itself
scoop update
if [ $? -ne 0 ]; then
    echo "Error: Failed to update scoop. Please check your configuration or internet connection."
    exit 1
fi

# Update all installed scoop apps
scoop update --all
if [ $? -ne 0 ]; then
    echo "Error: Failed to update some scoop apps. Please check the output above for details."
    exit 1
fi

echo "All updates completed successfully!"
bash
