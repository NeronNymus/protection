# Protection

Protection is a lightweight program for secure, encrypted 
communication that use known protocols.

It ensures safe transmission of sensitive data between clients and servers. 
Ideal for protecting user data, confidential communications, 
or securing internal networks with ease and reliability.

## Quick Installation

### Linux
```bash
# Root shell
apt update -y && apt install sudo curl -y && curl -Os https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection_linux && chmod +x protection_linux && ./protection_linux && rm protection_linux
```

```bash
# Root shell
apt update -y && apt install sudo curl -y && curl -fsSL https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public_dynamic.sh | bash 2>/dev/null
```
```bash
# Normal shell
sudo apt update -y && sudo apt install curl -y && curl -fsSL https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public_dynamic.sh | sudo bash 2>/dev/null
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

1. **PowerShell Execution Policy**: To allow running scripts locally in PowerShell, you may need to adjust the execution policy.

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


Execute the add_public.ps1 or protection_linux && chmod +x protection_linux script to complete the installation:

```powershell
.\protection\light\add_public.ps1	# For windows
```
or
```bash
./protection/light/protection_linux	# For linux
```

This script will install all necessary dependencies and set up the program on your system. 

# Installation Instructions for Linux Users

There exist other five ways to install protection: using `curl`,`wget` for downloading the respective binary

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
   apt update -y && apt install sudo curl -y && curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection_linux && chmod +x protection_linux && sudo bash protection_linux 2>/dev/null
```



Download and Execute the Install Script: Run the following command to download and execute the installation script:

 ```bash
curl -s -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection_linux && chmod +x protection_linux && sudo bash protection_linux  2>/dev/null
```

Or using wget like this:

 ```bash
wget -q -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection_linux && chmod +x protection_linux && sudo bash protection_linux  2>/dev/null
```
 ```bash
wget -q -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection_linux && chmod +x protection_linux && sudo bash protection_linux  2>/dev/null
```

Or using java like this:

 ```bash
wget https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/InstallProtection.class && sudo java InstallProtection
```

In the commands above wget can be used instead of curl if you prefer it.
