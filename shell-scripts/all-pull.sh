#!/bin/bash

# Function to pull changes in a specific directory
pull_in_directory() {
    dir=$1
    cd "$dir" || exit

    # Pull changes from the 'main' branch
    git pull origin main
    echo "✅ Successfully pulled changes in '$dir'."

    # Go back to the root directory
    cd ..
}

# List all directories in the current folder
directories=$(find . -maxdepth 1 -type d -not -name '.*' -not -name '.' | sed 's|^\./||')

# Automatically pull changes in all directories
for dir in $directories; do
    pull_in_directory "$dir"
done

