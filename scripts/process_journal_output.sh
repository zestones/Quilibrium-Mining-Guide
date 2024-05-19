#!/bin/bash

# ================================================================================================ #
#                     S E T T I N G S   &   D E F A U L T   V A L U E S                            #
# ================================================================================================ #

# Read the output_log_file from the ./.conf file
output_log_file=$(grep -oP '(?<=output_log_file=).*' ./.conf)
journalctl_cmd="sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat"
last_frame_number=0

# ----------------------------------------------------------------------------------------------- #

# If the output_log_file is not found in the ./.conf file, set a default value
if [[ -z "$output_log_file" ]]; then
    echo "output_log_file not found in .conf file. Creating a default output_log_file..."
    output_log_file="./output.log"
fi

# if the output_log_file does not exist, create it
if [[ ! -f "$output_log_file" ]]; then
    mkdir -p "$(dirname "$output_log_file")"
    touch "$output_log_file"
fi

# read from the output_log_file the last frame_number
if [[ -f "$output_log_file" ]]; then
    last_frame_number=$(tail -n 1 "$output_log_file" | grep -oP '(?<=Block ID: )\d+')
fi


# ================================================================================================ #
#                     F U N C T I O N S   &   C O M M A N D S                                      #
# ================================================================================================ #
#     The process_log_entry function processes the log entry and writes to the output log file     #
# ------------------------------------------------------------------------------------------------ #
 
process_log_entry() {
    local line="$1"
    local first_run="$2"
    
    # Extract timestamp, frame_number, peer_store_count, and network_peer_count
    timestamp=$(echo "$line" | grep -oP '(?<="ts":)\d+\.\d+')
    frame_number=$(echo "$line" | grep -oP '(?<="frame_number":)\d+')

    # Convert timestamp to human-readable format
    readable_timestamp=$(date -d @${timestamp%.*} +"%Y-%m-%d %H:%M:%S")

    # Write to output log file if frame_number is present
    if [[ -n "$frame_number" ]]; then
        echo -n "$readable_timestamp, Block ID: $frame_number" >> "$output_log_file"
        if [[ "$first_run" = true ]]; then
            echo -n ", STARTED" >> "$output_log_file"
            first_run=false
        fi
        echo "" >> "$output_log_file"  # Add a newline after each log entry
    fi
}


# ================================================================================================ #
#                          M A I N   L O G I C   &   L O O P                                       #
# ================================================================================================ #


# Start the ceremonyclient service
sudo service ceremonyclient start 
first_run=true
$journalctl_cmd | while read -r line; do
    new_frame_number=$(echo "$line" | grep -oP '(?<="frame_number":)\d+')

    # Check if new_frame_number is found and not empty
    if [[ -n "$new_frame_number" ]]; then
        # Check if new block is mined (last_frame_number != new_frame_number)
        echo "last_frame_number: $last_frame_number, new_frame_number: $new_frame_number"
        if [[ "$last_frame_number" -ne "$new_frame_number" ]]; then
            last_frame_number=$new_frame_number

            process_log_entry "$line" "$first_run"
            first_run=false
        fi
    # check if we find this message Stopped Ceremony Client Go App Service.
    else
        if [[ "$line" == *"Stopped Ceremony Client Go App Service."* ]]; then
            first_run=true
        fi
    fi

    # Print log entry to console
    echo "$line"
done
