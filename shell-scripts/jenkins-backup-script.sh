#!/bin/bash
set -e

# Jenkins Docker volume path
VOLUME_PATH="/home/ec2-user/jenkins_data"

# S3 bucket
S3_BUCKET="s3://ullagalliu-artifacts/jenkins_folder"

# Temporary backup file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="/tmp/jenkins-backup-$TIMESTAMP.tar.gz"

echo "++++ Dynamically fetch container name ++++"

CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -i jenkins | head -1)

if [ -z "$CONTAINER_NAME" ]; then
  echo "ERROR: No Jenkins container found."
  exit 1
fi

echo "Using Jenkins container: $CONTAINER_NAME"

echo "=== Stopping Jenkins container for clean backup ==="
docker stop "$CONTAINER_NAME" || true

echo "=== Creating Jenkins backup archive ==="
sudo tar -czf "$BACKUP_FILE" -C "$VOLUME_PATH" .

echo "=== Starting Jenkins container again ==="
docker start "$CONTAINER_NAME"

echo "=== Uploading backup to S3 ==="
aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/"

echo "=== Cleaning temporary files ==="
sudo rm -f "$BACKUP_FILE"

echo "=== Jenkins backup completed successfully ==="
