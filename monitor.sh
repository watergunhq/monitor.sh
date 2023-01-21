#!/bin/bash

MONITOR_VERSION="0.0.1"
MONITOR_ENDPOINT="https://nodes.watergun.app/stats"
API_KEY=$(cat ~/.watergun/api_key)

# collect CPU usage data for 10 seconds
sar 1 10 >/tmp/cpu_usage.txt

# get average CPU usage
cpu_usage=$(cat /tmp/cpu_usage.txt | awk '{if ($3 ~ /^[0-9.]+$/) {u += $3; c++}} END {print (u/c)}')

# read /proc/meminfo
mem_info=$(cat /proc/meminfo)

# extract values of MemTotal, MemFree and MemAvailable
mem_total=$(echo "$mem_info" | grep MemTotal | awk '{print $2}')
mem_free=$(echo "$mem_info" | grep MemFree | awk '{print $2}')
mem_available=$(echo "$mem_info" | grep MemAvailable | awk '{print $2}')

# get disk capacity and used space in bytes for the disk that mounts "/"
disk_info=$(df -B 1 / | tail -1)
disk_total=$(echo $disk_info | awk '{print $2}')
disk_used=$(echo $disk_info | awk '{print $3}')

# get hostname
hostname=$(hostname)

# get operating system and version
os=$(cat /etc/os-release | grep PRETTY_NAME | awk -F '"' '{print $2}')

# get kernel version
kernel=$(uname -r)

# format data as JSON payload
stats=$(jq -n \
        --arg monitor_version "$monitor_version" \
        --arg cpu_usage "$cpu_usage" \
        --arg mem_total "$mem_total" \
        --arg mem_free "$mem_free" \
        --arg mem_available "$mem_available" \
        --arg disk_total "$disk_total" \
        --arg disk_used "$disk_used" \
        --arg hostname "$hostname" \
        --arg os "$os" \
        --arg kernel "$kernel" \
        '{monitor_version: $MONITOR_VERSION, cpu_usage: $cpu_usage, mem_total: $mem_total, mem_free: $mem_free, mem_available: $mem_available, disk_total: $disk_total, disk_used: $disk_used, hostname: $hostname, os: $os, kernel: $kernel}')

curl -X POST -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d "$stats" $MONITOR_ENDPOINT
