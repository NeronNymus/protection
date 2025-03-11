#!/bin/bash

user="nobody1"

# DNS resolution can be used for this
host=155.248.218.192

# Generate the private key
key_path="$HOME/.ssh/$(whoami)_ed25519"
#ssh-keygen -t ed25519 -f "$key_path" -N ""  # Generate a key without a passphrase

# Append public key into remote B server
ssh-copy-id -i "$key_path.pub" "$user@$host"  # Use password for the initial copy

# Request a port number from the server (this could be handled by the server's API)
#received_port=$(curl -s "http://$host/info")
received_port=2001

# Set up the reverse tunnel using the received port
ssh -i "$key_path" -N -R "$received_port":localhost:22 "$host" &

# Create a systemd service to ensure the reverse tunnel runs on boot
cat << EOF | sudo tee /etc/systemd/system/reverse-tunnel.service
[Unit]
Description=Reverse SSH Tunnel Service
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/ssh -i $key_path -N -R $received_port:localhost:22 "$user@$host"
Restart=always
RestartSec=3
Environment=KEY_PATH=$key_path

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to apply the changes
sudo systemctl daemon-reload

# Enable the service so that it starts on boot
sudo systemctl enable reverse-tunnel.service

# Start the service immediately
sudo systemctl start reverse-tunnel.service

echo "Reverse tunnel setup complete. The service is now running and will reconnect after reboot."
