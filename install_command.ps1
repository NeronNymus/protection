Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NeronNymus/Secuserver/main/install.ps1" -OutFile "$env:TEMP\install.ps1"; & "$env:TEMP\install.ps1"
