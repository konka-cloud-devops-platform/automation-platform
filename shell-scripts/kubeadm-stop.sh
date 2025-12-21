#!/bin/bash

declare -A instances=(
    ["master.konkas.tech"]="i-077220aaa31722e50"
    ["node1.konkas.tech"]="i-037e4c8b4383c6c7b"
    ["node2.konkas.tech"]="i-06e7d82cec627e3ae"
)

for hostname in "${!instances[@]}"; do
    instance_id="${instances[$hostname]}"
    echo "Stopping instance $hostname ($instance_id)..."
    aws ec2 stop-instances --instance-ids "$instance_id"
done

echo "All instances have been requested to stop."
