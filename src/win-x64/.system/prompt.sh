if [ $# -ne 2 ]; then
    echo "Usage: $0 <filename> <color_code>"
    exit 1
fi

PROMPT="$1"
COLOR="\033[$2m"

records=()
record=""
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
    echo -e "[32m${records[$random]}[0m"
fi
