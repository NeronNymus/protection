# Protection

Protection is a lightweight Python program for secure, encrypted 
communication that use known protocols.

It ensures safe transmission of sensitive data between clients and servers. 
Ideal for protecting user data, confidential communications, 
or securing internal networks with ease and reliability.

## Installation Instructions for Windows Users

Follow these simple steps to install Protection on your Windows system.

### Prerequisites

1. **Python**: Ensure that you have Python installed on your system. If not, download and install the latest version of Python 
from [python.org](https://www.python.org/downloads/).
   
2. **Git**: Install Git if you don't already have it. You can download it from [git-scm.com](https://git-scm.com/).

3. **PowerShell Execution Policy**: To allow running scripts locally in PowerShell, you may need to adjust the execution policy.

    - **Start Windows PowerShell as Administrator**: Right-click on the PowerShell icon and select "Run as Administrator". 
	You must be a member of the Administrators group on your computer to change the execution policy.

    - **Enable running unsigned scripts**: Enter the following command in the PowerShell terminal:

      ```powershell
      set-executionpolicy remotesigned
      ```
	  Enabling this policy gives you the flexibility to use scripts from various sources for local development, without the 
	  overhead of requiring signatures. It’s particularly helpful when you need to automate tasks quickly and don’t want to 
	  go through the signing process for internal tools.


### Quick Installation

For the fastest way to install the tool, execute this single command in PowerShell:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.ps1" -OutFile "$env:TEMP\install_protection.ps1"; & "$env:TEMP\install_protection.ps1"

```

This will automatically download the install.ps1 script and execute it to complete the setup.

### Detailed Installation Steps

1. **Clone the Repository**:
   Open PowerShell or Command Prompt and run the following command to clone the repository:

```powershell
   git clone git@github.com:NeronNymus/protection.git
```

### Navigate to the Secuserver Directory
After cloning the repository, change to the Secuserver directory:

```powershell
cd protection
```

Execute the install.ps1 script to complete the installation:

```powershell
.\install_protection.ps1
```

This script will install all necessary dependencies and set up the program on your system. 
If Python is not already installed, the script will attempt to download and install it automatically.

# Installation Instructions for Linux Users

There are two ways to install SecuServer: using `curl` or the Python interpreter.

## Option 1: Install Using curl

1. **Install curl (if you don't have it already):**

```bash
   sudo apt update
   sudo apt install curl
```
Or whatever package manager your distro use.

Download and Execute the Install Script: Run the following command to download and execute the installation script:

 ```bash
curl -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.py && sudo python3 install_protection.py
```


## Option 2: Install Using Python
2. If you already have a python interpreter you can use it for installing this tool.
All you need is the 'requests' library, fetch it with

```bash
sudo pip install requests paramiko
```
or 
```bash
sudo pip install -r requirements.txt
```

Now, download the istallation script:

```bash
python3 -c "import requests; r = requests.get('https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.py'); open('install_protection.py', 'wb').write(r.content)"
```

Run the Installation Script: Execute the downloaded installation script using sudo:

```bash
sudo python3 install_protection.py
```

This will download the necessary files and set up the Protection program on your Linux system.
