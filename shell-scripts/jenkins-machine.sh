#!/bin/bash

HOSTED_ZONE_ID="Z03345832QRDQYLQ53NTN"
RECORD_NAME="jm.ullagallubuffellomilk.store"

AMI_ID=$(aws ec2 describe-images \
    --owners "amazon" \
    --region ap-south-1 \
    --filters "Name=name,Values=al2023-ami-2023*" "Name=state,Values=available" \
    --query "Images | sort_by(@, &CreationDate)[-1].ImageId" \
    --output text)

if [ -z "$AMI_ID" ]; then
  echo "Error: Failed to retrieve the latest Amazon Linux 3 AMI ID."
  exit 1
fi

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t3.micro \
  --key-name dev \
  --user-data file://jenkins-installation.sh \
  --instance-market-options "MarketType=spot,SpotOptions={SpotInstanceType=one-time}" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins}]' \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=8,VolumeType=gp3,DeleteOnTermination=true}' \
  --query 'Instances[0].InstanceId' \
  --output text)

if [ -z "$INSTANCE_ID" ]; then
  echo "Error: Failed to launch the EC2 instance."
  exit 1
fi

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [ -z "$PUBLIC_IP" ]; then
  echo "Error: Failed to retrieve the public IP address for instance $INSTANCE_ID."
  exit 1
fi

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "{
      \"Changes\": [{
          \"Action\": \"UPSERT\",
          \"ResourceRecordSet\": {
              \"Name\": \"$RECORD_NAME\",
              \"Type\": \"A\",
              \"TTL\": 1,
              \"ResourceRecords\": [{\"Value\": \"$PUBLIC_IP\"}]
          }
      }]
  }"

echo "Instance launched with ID: $INSTANCE_ID and DNS record $RECORD_NAME updated to IP: $PUBLIC_IP"
