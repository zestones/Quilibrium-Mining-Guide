#!/bin/bash

# Step 1: Move to the working directory
WORKING_DIR="/root/ceremonyclient/node"
cd $WORKING_DIR

SLEEPING_TIME=1200 # 20 minutes

# get HOME directory
HOME_DIR=$(eval echo ~$USER)
OUTPUT_FILE="$HOME_DIR/output/node-infos.csv"

mkdir -p $HOME_DIR/output
# Initialize the CSV file with headers if it does not exist
if [ ! -f $OUTPUT_FILE ]; then
    touch $OUTPUT_FILE
    echo "Timestamp,Version,Max Frame,Peer Score,Unclaimed Balance" > $OUTPUT_FILE
fi

while true; do
    # Step 2: Get the node's information by running ./node-1.4.19-linux-amd64 -node-info command
    OUTPUT=$(./node-1.4.19-linux-amd64 -node-info)

    # Extract the necessary information
    VERSION=$(echo "$OUTPUT" | grep "Version" | awk '{print $2}')
    MAX_FRAME=$(echo "$OUTPUT" | grep "Max Frame" | awk '{print $3}')
    PEER_SCORE=$(echo "$OUTPUT" | grep "Peer Score" | awk '{print $3}')
    UNCLAIMED_BALANCE=$(echo "$OUTPUT" | grep "Unclaimed balance" | awk '{print $3}')

    # Get the current timestamp
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    # Append the extracted information into the CSV file
    echo "$TIMESTAMP,$VERSION,$MAX_FRAME,$PEER_SCORE,$UNCLAIMED_BALANCE" >> $OUTPUT_FILE

    echo "✅ Done."

    # Sleep for the defined period
    sleep $SLEEPING_TIME
done
