#!/bin/bash

echo "Please enter the DNS record name (e.g., docker.konka.online): "
read NAME

HOSTED_ZONE_ID="Z05358812YCB33LWR8F1V"  
RECORD_NAME="${NAME}.konka.online"


echo "Please enter the instance type (e.g., t3a.medium, t3.medium.......): "
read INSTANCE_TYPE



echo "Do you want to launch a Spot instance or an On-Demand instance? (Enter 'spot' or 'on-demand')"
read INSTANCE_TYPE_CHOICE


echo "Please enter the region (e.g., us-east-1, ap-south-1.......): "
read REGION


if [[ "$INSTANCE_TYPE_CHOICE" != "spot" && "$INSTANCE_TYPE_CHOICE" != "on-demand" ]]; then
  echo "Invalid input! Please enter 'spot' or 'on-demand'."
  exit 1
fi


if [[ "$INSTANCE_TYPE_CHOICE" == "spot" ]]; then
  INSTANCE_MARKET_OPTIONS="--instance-market-options MarketType=spot,SpotOptions={SpotInstanceType=one-time}"
else
  INSTANCE_MARKET_OPTIONS=""  
fi


if [ -z "$INSTANCE_TYPE" ]; then
  echo "Error: Instance type cannot be empty."
  exit 1
fi

AMI_ID=$(aws ec2 describe-images \
    --owners "amazon" \
    --region "$REGION" \
    --filters "Name=name,Values=al2023-ami-2023*" "Name=state,Values=available" "Name=architecture,Values=x86_64" \
    --query "Images | sort_by(@, &CreationDate)[-1].ImageId" \
    --output text)

if [ -z "$AMI_ID" ]; then
  echo "Error: Failed to retrieve the latest Amazon Linux 3 AMI ID."
  exit 1
fi

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
  echo "No running instance found with tag $NAME, creating a new one..."

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name siva \
    --user-data file://docker-installation.sh \
    $INSTANCE_MARKET_OPTIONS \
    --iam-instance-profile Name=all-rounder \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" \
    --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=40,VolumeType=gp3,DeleteOnTermination=true}' \
    --query 'Instances[0].InstanceId' \
    --output text)

  if [ -z "$INSTANCE_ID" ]; then
    echo "Error: Failed to launch instance."
    exit 1
  fi

  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
  echo "Instance $INSTANCE_ID launched successfully."
else
  echo "Using existing running instance with ID $INSTANCE_ID."
fi

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [ -z "$PUBLIC_IP" ]; then
  echo "Error: Failed to retrieve the public IP address for instance $INSTANCE_ID."
  exit 1
fi

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
