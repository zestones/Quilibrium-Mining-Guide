#!/bin/bash

# Log file to write block mining information
output_log_file="mining_log.txt"

# Journalctl command to read the logs
journalctl_cmd="sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat"

# Function to process log entries and write to the output log file
process_log_entry() {
    local line="$1"
    
    # Extract timestamp, frame_number, peer_store_count, and network_peer_count
    timestamp=$(echo "$line" | grep -oP '(?<="ts":)\d+\.\d+')
    frame_number=$(echo "$line" | grep -oP '(?<="frame_number":)\d+')

    # Convert timestamp to human-readable format
    readable_timestamp=$(date -d @${timestamp%.*} +"%Y-%m-%d %H:%M:%S")

    # Write to ¥output log file if frame_number is present
    if [[ -n "$frame_number" ]]; then
        echo "$readable_timestamp, Block ID: $frame_number >> "$output_log_file""
    fi
}

# Run journalctl command and process each line
last_frame_number=0
$journalctl_cmd | while read -r line; do
    new_frame_number=$(echo "$line" | grep -oP '(?<="frame_number":)\d+')
    # Check if new block is mined last_frame_number != new_frame_number
    if [[ "$last_frame_number" != "$new_frame_number" ]]; then
        last_frame_number=$new_frame_number

        # Process log entry
        process_log_entry "$line"
    fi

    # Print log entry
    echo "$line"
done