#!/bin/bash

# Variables
JENKINS_HOME="/var/lib/jenkins"
JENKINS_CLI="/usr/share/jenkins/jenkins-cli.jar"
JENKINS_URL="http://jm.ullagallubuffellomilk.store:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Step 1: Skip the initial password
if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
    echo "Removing initial admin password file to skip setup wizard..."
    sudo rm -f "$JENKINS_HOME/secrets/initialAdminPassword"
else
    echo "Initial admin password file already removed."
fi

# Step 2: Start Jenkins if not already running
echo "Ensuring Jenkins is running..."
sudo systemctl start jenkins
sleep 30 # Wait for Jenkins to start

# Step 3: Install required plugins
echo "Installing required plugins..."
PLUGINS=("configuration-as-code" "job-dsl")
for plugin in "${PLUGINS[@]}"; do
    curl -X POST -u "$ADMIN_USER:$ADMIN_PASSWORD" \
        "$JENKINS_URL/pluginManager/installNecessaryPlugins" \
        -d "<jenkins><install plugin=\"$plugin@latest\"/></jenkins>" \
        --header "Content-Type: text/xml" || {
            echo "Failed to install plugin $plugin."
            exit 1
        }
done

# Step 4: Set up the admin user (ensure directory exists)
echo "Setting up admin user..."
sudo mkdir -p "$JENKINS_HOME/users/$ADMIN_USER"
cat <<EOF | sudo tee "$JENKINS_HOME/users/$ADMIN_USER/config.xml"
<?xml version='1.1' encoding='UTF-8'?>
<user>
  <fullName>$ADMIN_USER</fullName>
  <properties>
    <hudson.security.HudsonPrivateSecurityRealm_-Details>
      <passwordHash>#jbcrypt:${ADMIN_PASSWORD}</passwordHash>
    </hudson.security.HudsonPrivateSecurityRealm_-Details>
  </properties>
</user>
EOF

# Step 5: Restart Jenkins to apply changes
echo "Restarting Jenkins to apply changes..."
sudo systemctl restart jenkins
echo "Jenkins setup completed! Admin user is '$ADMIN_USER' with password '$ADMIN_PASSWORD'."
