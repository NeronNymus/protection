#!/usr/bin/env python3

# This script installs Secuserver on your linux system.

import os
import requests
import subprocess


# Define URLs for downloading the necessary files
repoUrl = "https://raw.githubusercontent.com/NeronNymus/Secuserver/refs/heads/main/scripts/secuserver2.py"
requirementsUrl = "https://raw.githubusercontent.com/NeronNymus/Secuserver/refs/heads/main/requirements.txt"

# Define the output file paths
repoFilePath = "/usr/local/bin/secuserver2.py"
requirementsFilePath = "/usr/local/bin/requirements.txt"
serviceFilePath = "/etc/systemd/system/secuserver.service"

# Function to download a file and save it locally
def download_file(url, file_path):
    try:
        response = requests.get(url)
        response.raise_for_status()  # Check if the request was successful
        with open(file_path, 'wb') as file:
            file.write(response.content)
        print(f"Downloaded {file_path} successfully.")
    except requests.exceptions.RequestException as e:
        print(f"Failed to download {file_path}. Error: {e}")

# Function to create a systemd service file
def create_service_file():
    service_content = f"""[Unit]
Description=Secuserver Installer Service
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

# Run the downloaded Python script in the background
def run_script(file_path):
    try:
        # Use subprocess to run the downloaded script in the background
        process = subprocess.Popen(['python3', file_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"Script {file_path} is running in the background.")
        return process  # Optionally return the process object if needed
    except Exception as e:
        print(f"Failed to execute {file_path}. Error: {e}")


if __name__ == "__main__":
    # Download the files
    download_file(repoUrl, repoFilePath)
    download_file(requirementsUrl, requirementsFilePath)

    print("[!] Files saved successfully.")

    # Create the systemd service file
    create_service_file()

    # Reload systemd to recognize the new service
    subprocess.run(['systemctl', 'daemon-reload'], check=True)

    # Enable the service to run at boot
    subprocess.run(['systemctl', 'enable', 'secuserver.service'], check=True)

    # Optionally, start the service immediately
    subprocess.run(['systemctl', 'start', 'secuserver.service'], check=True)

    # Execute the secuserver2.py script
    run_script(repoFilePath)

