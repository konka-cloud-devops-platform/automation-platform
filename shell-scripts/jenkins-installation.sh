#!/bin/bash

# Variables
LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging function
LOG() {
    local message="$1"
    local status="$2"
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}${message} succeeded${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}${message} failed${NC}" | tee -a "$LOG_FILE"
    fi
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root or with sudo privileges${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Idempotent Java installation
if ! rpm -q java-17-amazon-corretto &>>"$LOG_FILE"; then
    dnf install java-17-amazon-corretto -y &>>"$LOG_FILE"
    LOG "Java 17 Amazon Corretto installation" $?
else
    LOG "Java 17 Amazon Corretto already installed" 0
fi

# Update packages
dnf update -y &>>"$LOG_FILE"
LOG "System update" $?

# Jenkins repo setup
if [ ! -f /etc/yum.repos.d/jenkins.repo ]; then
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo &>>"$LOG_FILE"
    LOG "Jenkins repo download" $?
    
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key &>>"$LOG_FILE"
    LOG "Jenkins repo key import" $?
else
    LOG "Jenkins repo already exists" 0
fi

# Idempotent Jenkins installation
if ! rpm -q jenkins &>>"$LOG_FILE"; then
    dnf install jenkins -y &>>"$LOG_FILE"
    LOG "Jenkins installation" $?
else
    LOG "Jenkins already installed" 0
fi

# Enable and start Jenkins service
systemctl daemon-reload &>>"$LOG_FILE"
systemctl enable jenkins &>>"$LOG_FILE"
LOG "Jenkins service enable" $?

systemctl start jenkins &>>"$LOG_FILE"
LOG "Jenkins service start" $?
