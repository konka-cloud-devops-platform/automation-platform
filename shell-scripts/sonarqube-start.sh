#!/bin/bash
HOSTED_ZONE_ID="Z03345832QRDQYLQ53NTN"
INSTANCE_ID="i-0cbc5d64962ecb410"
DNS_NAME="sonar.ullagallu.in"
read -p "Please Enter Desired Instance Type: " NEW_INSTANCE_TYPE

# Check the current state of the EC2 instance
current_state=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].State.Name' --output text)
echo "Current instance state: $current_state"

# Stop the EC2 instance if it is running
if [[ "$current_state" == "running" ]]; then
    echo "Stopping EC2 instance for WorkStation..."
    aws ec2 stop-instances --instance-ids $INSTANCE_ID
    aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
    echo "Instance stopped."
else
    echo "Instance is already stopped. Skipping stop operation."
fi

# Change the instance type if a new instance type is provided
if [[ -n $NEW_INSTANCE_TYPE ]]; then
    echo "Modifying the instance type to $NEW_INSTANCE_TYPE..."
    aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type "{\"Value\": \"$NEW_INSTANCE_TYPE\"}"
    echo "Instance type changed to $NEW_INSTANCE_TYPE."
else
    echo "No new instance type provided. Skipping instance type modification."
fi

# Start EC2 instance for WorkStation
echo "Starting EC2 instance for WorkStation..."
aws ec2 start-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get the public IPv4 address
ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
echo "Instance ID: $INSTANCE_ID, IPv4: $ipv4_address"

# Construct the payload to update Route 53 DNS records
payload='{"Changes": [{"Action": "UPSERT","ResourceRecordSet": {"Name": "'"$DNS_NAME"'","Type": "A","TTL": 1,"ResourceRecords": [{"Value": "'"$ipv4_address"'"}]}}]}'

# Update Route 53 DNS record
echo "Updating DNS record for WorkStation..."
if aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch "$payload"; then
    echo "DNS update for WorkStation was successful."
else
    echo "Failed to update DNS record for WorkStation."
fi

# Verify the updated Route 53 record
echo "Verifying DNS record..."
updated_record=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query "ResourceRecordSets[?Type == 'A' && Name == '$DNS_NAME.'].[Name, ResourceRecords[0].Value]" --output text)
echo "Updated record: $updated_record"
