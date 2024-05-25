#!/bin/bash

# ================================================================================================ #
#                     S E T T I N G S   &   D E F A U L T   V A L U E S                            #
# ================================================================================================ #

# Read the output_log_file from the ./.conf file
output_log_file=$(grep -oP '(?<=output_log_file=).*' ./.conf)

# ----------------------------------------------------------------------------------------------- #

# request script to be run with sudo
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi

# If the output_log_file is not found in the ./.conf file, set a default value
if [[ -z "$output_log_file" ]]; then
    echo "output_log_file not found in .conf file. Exiting..."
    exit 1
fi

# if the output_log_file does not exist, create it
if [[ ! -f "$output_log_file" ]]; then
    mkdir -p "$(dirname "$output_log_file")"
    touch "$output_log_file"
fi

# -------------------------------------------------------------------- #
# Function to analyze network traffic and determine if mining is stuck #
# -------------------------------------------------------------------- #
analyze_network_traffic() {   
    # Get the date and time from the last line of the output log file
    last_date_time=$(tail -n 1 "$output_log_file" | grep -oP '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}')

    # if date not found, return
    if [[ -z "$last_date_time" ]]; then
        return
    fi

    current_time=$(date +%s)
    restarting_time=14400    # 4 hours
    last_date_time_seconds=$(date -d "$last_date_time" +%s)

    # Check if the last date and time is within the specified time difference
    if [[ -n "$last_date_time" ]] && (( current_time - last_date_time_seconds > restarting_time )); then
        echo "> Last date and time is beyond the specified restarting time."
        network_activity=$(iftop -t -s 5 -n -N)

        # Extract total network send and receive rates
        total_send_rate=$(echo "$network_activity" | awk '/Total send rate/ { print $4 }')
        total_receive_rate=$(echo "$network_activity" | awk '/Total receive rate/ { print $4 }')

        # Convert kilobits to bytes
        total_send_rate_bytes=$(awk "BEGIN { print int($total_send_rate * 128) }")
        total_receive_rate_bytes=$(awk "BEGIN { print int($total_receive_rate * 128) }")

        echo "Total send rate: $total_send_rate_bytes bytes/s"
        echo "Total receive rate: $total_receive_rate_bytes bytes/s"

        send_threshold=25600     # 25 KB/s
        receive_threshold=76800  # 75 KB/s

        if (( total_send_rate_bytes < send_threshold )) && (( total_receive_rate_bytes < receive_threshold )); then
            echo "Network activity is low."

            echo "> STOPPED <" >> "$output_log_file"

            service ceremonyclient stop
            sleep 5
            service ceremonyclient start
            echo "Restarting mining node..."
            sleep 7200
        fi
    fi
}

while true; do
    analyze_network_traffic
done