#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <directory> <extension> <search_regex> <replacement>"
    echo "Example: $0 ./docs .txt 'old-word' 'new-word'"
    exit 1
fi

DIRECTORY=$1
EXTENSION=$2
SEARCH_REGEX=$3
REPLACEMENT=$4

# Check if the directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' not found."
    exit 1
fi

# Find files with the specific extension and perform in-place replacement
# -name "*$EXTENSION" filters files by their ending
# -type f ensures only files are processed
find "$DIRECTORY" -type f -name "*$EXTENSION" -exec sed -i "s|$SEARCH_REGEX|$REPLACEMENT|g" {} +

echo "Replacement complete for all *$EXTENSION files in $DIRECTORY."
