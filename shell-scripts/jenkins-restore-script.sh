#!/bin/bash
set -e

# Jenkins Docker volume path
VOLUME_PATH="/home/ec2-user/jenkins_data"

# S3 bucket path
S3_BUCKET="s3://ullagalliu-artifacts/jenkins_folder"

# Temp directory for restore
RESTORE_TMP="/tmp/jenkins-restore"
mkdir -p $RESTORE_TMP

echo "++++ Fetching latest backup from S3 ++++"

LATEST_BACKUP=$(aws s3 ls $S3_BUCKET/ | sort | tail -1 | awk '{print $4}')

if [ -z "$LATEST_BACKUP" ]; then
  echo "ERROR: No backup file found in S3."
  exit 1
fi

echo "Latest backup file: $LATEST_BACKUP"

echo "=== Downloading backup from S3 ==="
aws s3 cp "$S3_BUCKET/$LATEST_BACKUP" "$RESTORE_TMP/jenkins-restore.tar.gz"

# echo "++++ Detecting Jenkins container ++++"
# CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -i jenkins | head -1)

# if [ -z "$CONTAINER_NAME" ]; then
#   echo "WARNING: No Jenkins container running. Trying to find stopped container..."
#   CONTAINER_NAME=$(docker ps -a --format '{{.Names}}' | grep -i jenkins | head -1)
# fi

# if [ -z "$CONTAINER_NAME" ]; then
#   echo "ERROR: Jenkins container not found."
#   exit 1
# fi

# echo "Using Jenkins container: $CONTAINER_NAME"


# echo "=== Stopping Jenkins container ==="
# docker stop "$CONTAINER_NAME" || true

echo "=== Cleaning old Jenkins home ==="
sudo rm -rf "$VOLUME_PATH"/*
sudo mkdir -p "$VOLUME_PATH"

echo "=== Extracting backup ==="
sudo tar -xzf "$RESTORE_TMP/jenkins-restore.tar.gz" -C "$VOLUME_PATH"


echo "=== Cleaning temporary restore files ==="
rm -rf "$RESTORE_TMP"

echo "=== Jenkins restore completed successfully! ==="
