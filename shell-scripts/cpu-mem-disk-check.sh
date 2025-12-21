#!/bin/bash

echo "===== System Resource Usage ====="

# CPU Usage
echo "CPU Usage:"
# top command gives CPU usage, grep line with 'Cpu(s)', awk to get used %
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print "Used CPU: " $2 + $4 "%"}')
echo "$cpu_usage"
echo ""

# Memory Usage
echo "Memory Usage:"
# free command, awk to print used and total memory in MB
mem_usage=$(free -m | awk 'NR==2{printf "Used Memory: %sMB / Total Memory: %sMB (%.2f%%)\n", $3,$2,$3*100/$2 }')
echo "$mem_usage"
echo ""

# Disk Usage
echo "Disk Usage:"
# df -h shows human-readable, awk prints root filesystem usage
disk_usage=$(df -h / | awk 'NR==2{print "Used Disk: "$3" / Total Disk: "$2" ("$5")"}')
echo "$disk_usage"
echo "================================="
