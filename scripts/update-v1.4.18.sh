#!/bin/bash

# sudo request to launch services/systemctl commands
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo."
    exit 1
fi

echo "⏳You are upgrading your Quilibrium Node to v1.4.18!"
echo "⏳Processing..."
sleep 2  # Add a 10-second delay

# Stop the ceremonyclient service
service ceremonyclient stop

# Step 1:Download Binary
echo "⏳ Downloading New Release v1.4.18"
# repository path
repository_path="/root/ceremonyclient"
cd $repository_path
git pull
git checkout release

# Step 3:Re-Create Ceremonyclient Service
echo "⏳ Re-Creating Ceremonyclient Service"
sleep 2  # Add a 2-second delay
rm /lib/systemd/system/ceremonyclient.service
tee /lib/systemd/system/ceremonyclient.service > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
CPUQuota=1080%
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=${repository_path}/node
ExecStart=${repository_path}/node/node-1.4.18-linux-amd64

[Install]
WantedBy=multi-user.target
EOF

# Step 4:Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

# See the logs of the ceremonyclient service
echo "🎉 Welcome to Quilibrium Ceremonyclient v1.4.18"
echo "⏳ Please let it flow node logs at least 5 minutes then you can press CTRL + C to exit the logs."
sleep 5  # Add a 5-second delay
journalctl -u ceremonyclient.service -f --no-hostname -o cat