#!/bin/bash

# List of repository names
PROJECT_NAME=instana
REPOS=("catalogue" "cart" "user" "shipping" "payment" "frontend" "mongo" "mysql" "rabbit")

# Loop through each repo name and create it in ECR
for REPO in "${REPOS[@]}"; do
    echo "Creating ECR repository: $REPO"
    aws ecr create-repository --repository-name "$PROJECT_NAME/$REPO"
    if [ $? -eq 0 ]; then
        echo "Successfully created: $PROJECT_NAME/$REPO"
    else
        echo "Failed to create: $PROJECT_NAME/$REPO"
    fi
done
