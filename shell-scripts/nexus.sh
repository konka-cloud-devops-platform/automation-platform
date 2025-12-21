#!/bin/bash
# amz2023
# Define variables
JAVA_PACKAGE="java-21-amazon-corretto-devel"
NEXUS_URL="https://download.sonatype.com/nexus/3/nexus-3.83.2-01-linux-x86_64.tar.gz"
NEXUS_TMP_DIR="/tmp/nexus"
NEXUS_INSTALL_DIR="/opt/nexus"
SERVICE_FILE="/etc/systemd/system/nexus.service"
LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"

# Function to log messages with success or failure
log_message() {
    local message="$1"
    local status="$2"
    local color

    if [ "$status" -eq 0 ]; then
        color="\033[32m"  # Green for success
    else
        color="\033[31m"  # Red for failure
    fi

    echo -e "${color}${message}\033[0m"
}

# Install Java 17
echo "Installing Java 17..." | tee -a "$LOG_FILE"
dnf install -y "$JAVA_PACKAGE" &>> "$LOG_FILE"
log_message "Java 17 installation" $?

# Create necessary directories
echo "Creating directories..." | tee -a "$LOG_FILE"
mkdir -p "$NEXUS_TMP_DIR" "$NEXUS_INSTALL_DIR"

# Download and extract Nexus
echo "Downloading Nexus..." | tee -a "$LOG_FILE"
cd "$NEXUS_TMP_DIR" || exit
wget "$NEXUS_URL" -O nexus.tar.gz &>> "$LOG_FILE"
tar xzvf nexus.tar.gz &>> "$LOG_FILE"
NEXUS_DIR=$(tar -tf nexus.tar.gz | head -1 | cut -d '/' -f1)
rm -f nexus.tar.gz
log_message "Nexus download and extraction" $?

# Move Nexus files to installation directory
echo "Moving Nexus files..." | tee -a "$LOG_FILE"
cp -r "$NEXUS_TMP_DIR"/* "$NEXUS_INSTALL_DIR" &>> "$LOG_FILE"

# Create Nexus user
echo "Creating Nexus user..." | tee -a "$LOG_FILE"
useradd nexus &>> "$LOG_FILE"
chown -R nexus:nexus "$NEXUS_INSTALL_DIR" &>> "$LOG_FILE"
log_message "Nexus user creation" $?

# Create Nexus systemd service file
echo "Creating systemd service file..." | tee -a "$LOG_FILE"
cat <<EOT > "$SERVICE_FILE"
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUS_DIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUS_DIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT
log_message "Systemd service file creation" $?

# Configure Nexus to run as 'nexus' user
echo "Configuring Nexus to run as user 'nexus'..." | tee -a "$LOG_FILE"
echo 'run_as_user="nexus"' > "/opt/nexus/$NEXUS_DIR/bin/nexus.rc"
log_message "Nexus user configuration" $?

# Reload systemd and manage Nexus service
echo "Reloading systemd and managing Nexus service..." | tee -a "$LOG_FILE"
systemctl daemon-reload &>> "$LOG_FILE"
systemctl start nexus &>> "$LOG_FILE"
systemctl enable nexus &>> "$LOG_FILE"
log_message "Nexus service management" $?

echo "Nexus installation and configuration completed."
