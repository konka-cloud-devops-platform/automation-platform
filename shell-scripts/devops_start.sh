#!/bin/bash

# Define Instance Details
declare -A NODES
NODES=(
    ["jenkins.ullagallu.in"]="i-014d5345ca0f9f7c6"
    ["runner.ullagallu.in"]="i-053f6a4f0d8c7a0ed"
    # ["sonarqube.ullagallu.in"]="i-0d51f59d037663b7e"
)

HOSTED_ZONE_ID="Z03345832QRDQYLQ53NTN"

# Prompt for new instance type (optional)
read -p "Enter new instance type (leave empty to skip modification): " NEW_INSTANCE_TYPE

for DNS_NAME in "${!NODES[@]}"; do
    INSTANCE_ID=${NODES[$DNS_NAME]}
    echo "Processing $DNS_NAME (Instance ID: $INSTANCE_ID)..."

    # Get the current instance state
    current_state=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].State.Name' --output text)
    echo "Current state of $DNS_NAME: $current_state"

    # Stop the instance if running
    if [[ "$current_state" == "running" ]]; then
        echo "Stopping $DNS_NAME..."
        aws ec2 stop-instances --instance-ids $INSTANCE_ID
        aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
        echo "$DNS_NAME stopped."
    else
        echo "$DNS_NAME is already stopped."
    fi

    # Modify instance type if provided
    if [[ -n "$NEW_INSTANCE_TYPE" ]]; then
        echo "Changing instance type of $DNS_NAME to $NEW_INSTANCE_TYPE..."
        aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type "{\"Value\": \"$NEW_INSTANCE_TYPE\"}"
        echo "Instance type updated."
    fi

    # Start the instance
    echo "Starting $DNS_NAME..."
    aws ec2 start-instances --instance-ids $INSTANCE_ID
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    echo "$DNS_NAME started."

    # Get the new public IPv4 address
    ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    
    if [[ -z "$ipv4_address" ]]; then
        echo "Error: Failed to retrieve public IP address for $DNS_NAME."
        exit 1
    fi

    echo "New IPv4 address for $DNS_NAME: $ipv4_address"

    # Update Route 53 DNS record
    cat <<EOF > dns_update.json
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$DNS_NAME",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [{"Value": "$ipv4_address"}]
            }
        }
    ]
}
EOF

    echo "Updating Route 53 DNS record for $DNS_NAME..."
    aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://dns_update.json
    echo "DNS update completed for $DNS_NAME."

    # Verify the updated DNS record
    updated_record=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query "ResourceRecordSets[?Type == 'A' && Name == '$DNS_NAME.'].[Name, ResourceRecords[0].Value]" --output text)
    echo "Updated DNS record: $updated_record"
    
    # Cleanup
    rm -f dns_update.json
done

echo "✅ All nodes updated and restarted successfully!"
