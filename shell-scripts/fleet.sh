#!/bin/bash

echo "Please enter the DNS record name (e.g., docker.ullagallu.in): "
read NAME

HOSTED_ZONE_ID="Z03345832QRDQYLQ53NTN"  
RECORD_NAME="${NAME}.ullagallu.in"

# Step 1: Prompt for the instance type
echo "Please enter the instance type (e.g., t3a.medium, t3.medium.......): "
read INSTANCE_TYPE

# Step 2: Prompt for the instance tag
echo "Please enter the instance tag (e.g., Name=docker): "
read INSTANCE_TAG

# Step 3: Prompt for the instance market choice (Spot or On-Demand)
echo "Do you want to launch a Spot instance or an On-Demand instance? (Enter 'spot' or 'on-demand')"
read INSTANCE_TYPE_CHOICE

# Step 4: Prompt for the region
echo "Please enter the region (e.g., us-east-1, ap-south-1.......): "
read REGION

# Validate input for instance type choice
if [[ "$INSTANCE_TYPE_CHOICE" != "spot" && "$INSTANCE_TYPE_CHOICE" != "on-demand" ]]; then
  echo "Invalid input! Please enter 'spot' or 'on-demand'."
  exit 1
fi

# Ensure the input is not empty for instance type
if [ -z "$INSTANCE_TYPE" ]; then
  echo "Error: Instance type cannot be empty."
  exit 1
fi

# Step 5: Retrieve the latest Amazon Linux 2023 AMI ID
AMI_ID=$(aws ec2 describe-images \
    --owners "amazon" \
    --region "$REGION" \
    --filters "Name=name,Values=al2023-ami-2023*" "Name=state,Values=available" "Name=architecture,Values=x86_64" \
    --query "Images | sort_by(@, &CreationDate)[-1].ImageId" \
    --output text)

if [ -z "$AMI_ID" ]; then
  echo "Error: Failed to retrieve the latest Amazon Linux 2023 AMI ID."
  exit 1
fi

if [[ "$INSTANCE_TYPE_CHOICE" == "on-demand" ]]; then
  #######################################################
  #   ON-DEMAND INSTANCE LAUNCH
  #######################################################
  echo "Launching On-Demand instance..."

  # Check if there is already a running instance with the given tag
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_TAG" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --region "$REGION" \
    --output text)

  if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    INSTANCE_ID=$(aws ec2 run-instances \
      --image-id "$AMI_ID" \
      --instance-type "$INSTANCE_TYPE" \
      --key-name siva \
      --user-data file://docker-installation.sh \
      --region "$REGION" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_TAG}]" \
      --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=40,VolumeType=gp3,DeleteOnTermination=true}' \
      --query 'Instances[0].InstanceId' \
      --output text)

    if [ -z "$INSTANCE_ID" ]; then
      echo "Error: Failed to launch instance."
      exit 1
    fi

    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
    echo "Instance $INSTANCE_ID launched successfully."
  else
    echo "Using existing running instance with ID $INSTANCE_ID."
  fi

else
  #######################################################
  #   SPOT FLEET LAUNCH (AUTO FETCH SUBNET & SG)
  #######################################################
  echo "Launching Spot Fleet with default VPC, subnet, and SG..."

  # Get default VPC
  DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
  if [ -z "$DEFAULT_VPC_ID" ] || [ "$DEFAULT_VPC_ID" == "None" ]; then
    echo "Error: No default VPC found in $REGION."
    exit 1
  fi

  # Get default subnets in that VPC (use first one)
  SUBNET_ID=$(aws ec2 describe-subnets --region "$REGION" --filters Name=vpc-id,Values=$DEFAULT_VPC_ID --query 'Subnets[0].SubnetId' --output text)

  # Get default security group of that VPC
  DEFAULT_SG=$(aws ec2 describe-security-groups --region "$REGION" --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=group-name,Values=default --query 'SecurityGroups[0].GroupId' --output text)

  # Fleet config JSON
  FLEET_CONFIG_FILE="fleet-config.json"
  cat > $FLEET_CONFIG_FILE <<EOF
{
  "IamFleetRole": "arn:aws:iam::384570460482:role/SpotFleetRole",
  "TargetCapacity": 1,
  "AllocationStrategy": "lowestPrice",
  "LaunchSpecifications": [
    {
      "ImageId": "$AMI_ID",
      "InstanceType": "$INSTANCE_TYPE",
      "KeyName": "siva",
      "UserData": "$(base64 -w0 docker-installation.sh)",
      "BlockDeviceMappings": [
        {
          "DeviceName": "/dev/xvda",
          "Ebs": {
            "VolumeSize": 40,
            "VolumeType": "gp3",
            "DeleteOnTermination": true
          }
        }
      ],
      "SubnetId": "$SUBNET_ID",
      "SecurityGroups": [{"GroupId":"$DEFAULT_SG"}],
      "TagSpecifications": [
        {
          "ResourceType": "instance",
          "Tags": [
            {"Key": "Name", "Value": "$INSTANCE_TAG"}
          ]
        }
      ]
    }
  ]
}
EOF

  SPOT_FLEET_REQUEST_ID=$(aws ec2 request-spot-fleet \
    --spot-fleet-request-config file://$FLEET_CONFIG_FILE \
    --region "$REGION" \
    --query 'SpotFleetRequestId' \
    --output text)

  if [ -z "$SPOT_FLEET_REQUEST_ID" ]; then
    echo "Error: Failed to launch Spot Fleet."
    exit 1
  fi

  echo "Spot Fleet requested with ID: $SPOT_FLEET_REQUEST_ID"
  sleep 30  # wait for instance to launch

  INSTANCE_ID=$(aws ec2 describe-spot-fleet-instances \
    --spot-fleet-request-id "$SPOT_FLEET_REQUEST_ID" \
    --region "$REGION" \
    --query 'ActiveInstances[0].InstanceId' \
    --output text)

  if [ -z "$INSTANCE_ID" ]; then
    echo "Error: No instances launched yet."
    exit 1
  fi

  echo "Launched Spot instance with ID: $INSTANCE_ID"
fi

# Step 6: Get the public IP of the instance
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [ -z "$PUBLIC_IP" ]; then
  echo "Error: Failed to retrieve the public IP address for instance $INSTANCE_ID."
  exit 1
fi

# Step 7: Update Route 53 record
EXISTING_IP=$(aws route53 list-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --query "ResourceRecordSets[?Name=='$RECORD_NAME'].ResourceRecords[0].Value" \
  --output text)

if [ "$EXISTING_IP" == "$PUBLIC_IP" ]; then
  echo "DNS record for $RECORD_NAME already points to the correct IP ($PUBLIC_IP). No update needed."
else
  echo "Updating DNS record $RECORD_NAME to point to $PUBLIC_IP..."
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "{
        \"Changes\": [{
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$RECORD_NAME\",
                \"Type\": \"A\",
                \"TTL\": 60,
                \"ResourceRecords\": [{\"Value\": \"$PUBLIC_IP\"}]
            }
        }]}"
  echo "DNS record $RECORD_NAME updated to IP: $PUBLIC_IP"
fi

echo "Instance $INSTANCE_ID with IP $PUBLIC_IP is ready and DNS record updated."
