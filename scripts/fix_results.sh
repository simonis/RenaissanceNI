#!/bin/bash
#
# fix_results.sh - Ensure every Renaissance result JSON file carries a
# "-Dmode={mode}" entry in its "/environment/vm/args" array.
#
# Result files are expected to be named "result-{directory-name}-{mode}.json"
# where {directory-name} is the name of the directory containing the file.
# For each such file, if "/environment/vm/args" does not already contain
# "-Dmode={mode}", the entry is appended and a log line is printed.
#
# Usage: fix_results.sh <directory>

set -u

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory>" >&2
    exit 1
fi

DIRECTORY=$1

if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' not found." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: 'jq' was not found in PATH. Please install jq and retry." >&2
    exit 1
fi

# Iterate over all JSON files recursively (NUL-delimited to be safe with odd names).
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    dirname=$(basename "$(dirname "$file")")
    prefix="result-${dirname}-"

    # Only handle files matching "result-{directory-name}-{mode}.json".
    case "$filename" in
        "${prefix}"*.json) ;;
        *)
            echo "Skipping '$file': name does not match 'result-${dirname}-{mode}.json'" >&2
            continue
            ;;
    esac

    mode=${filename#"$prefix"}
    mode=${mode%.json}
    if [ -z "$mode" ]; then
        echo "Skipping '$file': empty mode in file name" >&2
        continue
    fi

    entry="-Dmode=${mode}"

    # Check whether the args array already contains the entry.
    # jq -e exits 0 for true, 1 for false/null, and >1 on parse/usage errors.
    present=$(jq -e --arg entry "$entry" \
            '(.environment.vm.args // []) | index($entry) != null' "$file" 2>/dev/null)
    rc=$?
    if [ "$rc" -gt 1 ]; then
        echo "Skipping '$file': not valid JSON or unreadable" >&2
        continue
    fi

    if [ "$present" = "true" ]; then
        continue
    fi

    # Add the entry, writing to a temp file first so the original is untouched on failure.
    tmp=$(mktemp "${file}.tmp.XXXXXX") || { echo "Error: cannot create temp file for '$file'" >&2; continue; }
    if jq --arg entry "$entry" '.environment.vm.args = ((.environment.vm.args // []) + [$entry])' \
            "$file" > "$tmp"; then
        mv -f "$tmp" "$file"
        echo "Modified '$file': added '$entry' to /environment/vm/args"
    else
        rm -f "$tmp"
        echo "Error: failed to update '$file'" >&2
    fi
done < <(find "$DIRECTORY" -type f -name '*.json' -print0)
