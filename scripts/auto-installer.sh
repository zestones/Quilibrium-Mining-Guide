#!/bin/bash

echo "# ================================================================================================ #
      #                      A U T O   I N S T A L L E R   S C R I P T                                   #
      # ================================================================================================ #"

# Step 1: Verify if the script is run with sudo
if [[ $EUID -ne 0 ]]; then
    echo "🔄Please run this script with sudo."
    exit 1
fi

# Step 2: Check if Git is installed
echo "⏳Installing Git..."
if ! [ -x "$(command -v git)" ]; then
    echo "❌ Git is not installed."
    apt install git -y
    sleep 2
fi

echo "✅ Git is installed."
echo "🔍 Checking Git version..."
git --version

# Step 3: Check if Go is installed
echo "⏳ Installing Go..."
if ! [ -x "$(command -v go)" ]; then
    echo "❌ Go is not installed."
    
    apt -q update
    wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
    tar -xvf go1.20.14.linux-amd64.tar.gz
    
    echo "\t> Moving Go to /usr/local..."
    mv go /usr/local

    echo "\t> Removing the downloaded tarball..."
    rm go1.20.14.linux-amd64.tar.gz

    # Set the Go environment variables
    echo "\t> Setting Go environment variables..."
    
    echo "GOROOT=/usr/local/go" >> ~/.bashrc
    echo "GOPATH=$HOME/go" >> ~/.bashrc
    echo "PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> ~/.bashrc
    source ~/.bashrc
    sleep 2
fi

echo "✅ Go is installed."
echo "🔍 Checking Go version..."
go version


# Step 4: Adjust network buffer sizes
echo "🌐 Adjusting network buffer sizes..."
if grep -q "^net.core.rmem_max=600000000$" /etc/sysctl.conf; then
  echo "✅ net.core.rmem_max=600000000 found inside /etc/sysctl.conf, skipping..."
else
  echo -e "\n# Change made to increase buffer sizes for better network performance for ceremonyclient\nnet.core.rmem_max=600000000" | tee -a /etc/sysctl.conf > /dev/null
fi
if grep -q "^net.core.wmem_max=600000000$" /etc/sysctl.conf; then
  echo "✅ net.core.wmem_max=600000000 found inside /etc/sysctl.conf, skipping..."
else
  echo -e "\n# Change made to increase buffer sizes for better network performance for ceremonyclient\nnet.core.wmem_max=600000000" | tee -a /etc/sysctl.conf > /dev/null
fi

sysctl -p


# Step 6: Install Quilibrium Node
echo "⏳ Installing Quilibrium Node..."
if [ -d ~/ceremonyclient ]; then
    # Check if backup directory ~/backup/qnode_keys exists, if not create it
    if [ ! -d ~/backup/qnode_keys ]; then
            # Step 5: Create backup folder
        echo "📂 Creating ~/backup/qnode_keys folder..."
        mkdir -p ~/backup/qnode_keys
        echo "✅ Done."
    fi
    
    # Check if files exist, then backup
    if [ -f ~/ceremonyclient/node/.config/keys.yml ]; then
        cp ~/ceremonyclient/node/.config/keys.yml ~/backup/qnode_keys/
        echo "✅ Backup of keys.yml created in ~/backup/qnode_keys folder"
    fi
    
    if [ -f ~/ceremonyclient/node/.config/config.yml ]; then
        cp ~/ceremonyclient/node/.config/config.yml ~/backup/qnode_keys/
        echo "✅ Backup of config.yml created in ~/backup/qnode_keys folder"
    fi
    
    # Remove existing directory ~/ceremonyclient
    echo "🗑️ Removing existing directory ~/ceremonyclient..."
    rm -rf ~/ceremonyclient
fi


cd ~
echo "⏳ Downloading Ceremonyclient..."
sleep 1
git clone https://github.com/QuilibriumNetwork/ceremonyclient.git
cd ~/ceremonyclient/
git checkout release


VERSION="1.4.18"             # Step 6.1: Set the Quilibrium Node version
ARCH=$(uname -m)             # Step 6.2: Get the system architecture
HOME=$(eval echo ~$HOME_DIR) # Step 6.3: Get the current user's home directory

if [ "$ARCH" = "x86_64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-arm64"
elif [ "$ARCH" = "arm64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-darwin-arm64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

# Step 7: Create Ceremonyclient Service
echo "⏳ Re-Creating Ceremonyclient Service"
sleep 2  # Add a 2-second delay

# Step 7.1: Check if the file exists before attempting to remove it
if [ -f "/lib/systemd/system/ceremonyclient.service" ]; then
    rm /lib/systemd/system/ceremonyclient.service
    echo "🗑️ ceremonyclient.service file removed."
else
    # If the file does not exist, inform the user
    echo "ceremonyclient.service file does not exist. No action taken."
fi

tee /lib/systemd/system/ceremonyclient.service > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=/root/ceremonyclient/node
ExecStart=$EXEC_START

[Install]
WantedBy=multi-user.target
EOF

# Step 8: Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

# Step 8: Final messages
echo "🎉 Now your node is starting!"
echo "🕒 Let it run for at least 30 minutes to generate your keys."
echo ""
echo "🔐 You can logout of your server if you want and login again later."
echo "🔒 After 30 minutes, backup your keys.yml and config.yml files."
echo "ℹ️ More info about this in the online guide: https://iri.quest/quilibrium-node-guide"
echo ""
echo "📜 Now I will show the node log below..."
echo "To exit the log, just type CTRL +C."

# Step 9: See the logs of the ceremonyclient service
sleep 5  # Add a 5-second delay
journalctl -u ceremonyclient.service -f --no-hostname -o cat