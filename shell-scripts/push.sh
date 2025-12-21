#!/bin/bash

# Function to commit in a specific directory
commit_in_directory() {
    dir=$1
    cd "$dir" || exit

    # Prompt for commit message
    read -p "Enter commit message for '$dir': " message

    # Stage changes, commit, and ask for confirmation
    git add .
    git commit -m "$message"
    read -p "Are you sure you want to push changes in '$dir'? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        git push origin "$branch_name"
        echo "✅ Changes have been successfully pushed from '$dir'."
    else
        echo "❌ Push aborted in '$dir'."
    fi

    # Go back to the root directory
    cd ..
}

# Prompt for branch name (since it will be the same for all commits)
read -p "Enter branch name: " branch_name

# List all directories in the current folder
directories=$(find . -maxdepth 1 -type d -not -name '.*' -not -name '.' | sed 's|^\./||')

# Display the directories with numbers
echo "Available directories:"
PS3="Please select a directory (by number): "
select dir in $directories; do
    if [[ -n "$dir" ]]; then
        commit_in_directory "$dir"
        break
    else
        echo "Invalid choice. Please select a valid directory."
    fi
done
