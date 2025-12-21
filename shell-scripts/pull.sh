#!/bin/bash

# Function to pull changes in a specific directory
pull_in_directory() {
    dir=$1
    cd "$dir" || exit

    # Ask for confirmation before pulling
    read -p "Are you sure you want to pull changes in '$dir'? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        git pull origin "$branch_name"
        echo "✅ Successfully pulled changes in '$dir'."
    else
        echo "❌ Pull aborted in '$dir'."
    fi

    # Go back to the root directory
    cd ..
}

# Prompt for branch name (since it will be the same for all pulls)
read -p "Enter branch name: " branch_name

# List all directories in the current folder
directories=$(find . -maxdepth 1 -type d -not -name '.*' -not -name '.' | sed 's|^\./||')

# Display the directories with numbers
echo "Available directories:"
PS3="Please select a directory (by number): "
select dir in $directories; do
    if [[ -n "$dir" ]]; then
        pull_in_directory "$dir"
        break
    else
        echo "Invalid choice. Please select a valid directory."
    fi
done
