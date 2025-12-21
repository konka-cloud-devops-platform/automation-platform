#!/bin/bash

LOG_FILE="/tmp/sonarqube_setup_$(date +%Y-%m-%d_%H-%M).log"

LOG() {
    echo -e "$1" &>>"$LOG_FILE"
    if [ "$2" -eq 0 ]; then
        echo -e "\e[32m[SUCCESS]\e[0m $1"
    else
        echo -e "\e[31m[FAILED]\e[0m $1"
    fi
}

# Check for sudo privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" &>>"$LOG_FILE"
    exit 1
fi

# Update system
apt update &>>"$LOG_FILE"
LOG "System update completed" $?

# Install OpenJDK 17
apt install -y openjdk-17-jdk &>>"$LOG_FILE"
LOG "OpenJDK 17 installation completed" $?

# Download SonarQube
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.2.77730.zip -P /opt &>>"$LOG_FILE"
LOG "SonarQube downloaded" $?

# Install unzip
apt install -y unzip &>>"$LOG_FILE"
LOG "Unzip installation completed" $?

# Unzip and move SonarQube
unzip /opt/sonarqube-9.9.2.77730.zip -d /opt &>>"$LOG_FILE"
LOG "SonarQube unzipped" $?
mv /opt/sonarqube-9.9.2.77730 /opt/sonar &>>"$LOG_FILE"
LOG "SonarQube moved to /opt/sonar" $?

# Create sonar user
useradd sonar &>>"$LOG_FILE"
LOG "Sonar user created" $?

# Set ownership
chown -R sonar:sonar /opt/sonar &>>"$LOG_FILE"
LOG "Ownership set for /opt/sonar" $?

# Configure sudoers file
if ! grep -q 'sonar' /etc/sudoers; then
    echo 'sonar   ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
    LOG "Sudoers configured for sonar user" $?
else
    LOG "Sudoers already configured for sonar user" 0
fi

# Create and configure systemd service
cat <<EOF | tee /etc/systemd/system/sonar.service &>>"$LOG_FILE"
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
User=sonar
ExecStart=/opt/sonar/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonar/bin/linux-x86-64/sonar.sh stop
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

LOG "SonarQube systemd service configured" $?

# Start and enable SonarQube service
systemctl start sonar &>>"$LOG_FILE"
LOG "SonarQube service started" $?
systemctl enable sonar &>>"$LOG_FILE"
LOG "SonarQube service enabled on boot" $?
