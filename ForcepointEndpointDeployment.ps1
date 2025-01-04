# Define target URL and output file path
$downloadUrl = "URL"
$targetPath = "C:\Temp\FORCEPOINT-ONE-ENDPOINT-x64.exe"

# Path to the flags
$UninstallFlagFile = "C:\Temp\UninstallSuccess.flag"
$InstallFlagFile = "C:\Temp\InstallSuccess.flag"
$RebootFlagFile = "C:\Temp\RebootPending.flag"

# Function to show a GUI notification
function Show-RebootPrompt {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("A system reboot is required to continue the installation process. Please reboot your system.", "Reboot Required", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
}

# Check if the installation success flag exists
if (Test-Path $InstallFlagFile) {
    Write-Host "Installation flag found at: $InstallFlagFile. Terminating script." -ForegroundColor Green
    exit
}

# Check if a reboot is pending
if (Test-Path $RebootFlagFile) {
    # Read the timestamp from the reboot flag
    $RebootTimestamp = Get-Content $RebootFlagFile | Out-String
    $RebootTimestamp = [datetime]::Parse($RebootTimestamp.Trim())

    # Get system uptime
    $SystemUptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

    if ($SystemUptime -lt $RebootTimestamp) {
        Write-Host "Reboot is still pending. Prompting user to reboot..." -ForegroundColor Yellow
        Show-RebootPrompt
        exit
    } else {
        Write-Host "System reboot detected. Continuing with the installation process." -ForegroundColor Green
        Remove-Item $RebootFlagFile -Force -ErrorAction SilentlyContinue
    }
}

# Ensure the target directory exists
New-Item -ItemType Directory -Path (Split-Path $targetPath) -Force -ErrorAction SilentlyContinue | Out-Null

# Download the file if it does not exist
if (-not (Test-Path $targetPath)) {
    Write-Host "Downloading file from $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $targetPath
    Write-Host "File downloaded successfully to $targetPath"
} else {
    Write-Host "File already exists at $targetPath"
}

# Verify that the agent file exists before proceeding
if (-not (Test-Path $targetPath)) {
    Write-Host "Required agent file not found at $targetPath. Terminating script." -ForegroundColor Red
    exit
}

# Check if the uninstallation success flag exists
$UninstallationSkipped = $false
if (Test-Path $UninstallFlagFile) {
    Write-Host "Uninstallation flag found at: $UninstallFlagFile. Skipping uninstallation." -ForegroundColor Yellow
    $UninstallationSkipped = $true
} else {
    # Uninstall Forcepoint DLP Endpoint
    Write-Host "Attempting to uninstall Forcepoint DLP Endpoint..."
    $ProductCode = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -like "*FORCEPOINT ONE ENDPOINT*" } |
        Select-Object -ExpandProperty PSChildName -ErrorAction SilentlyContinue

    if ($ProductCode) {
        $Password = 'Password'
        $LogFile = "C:\Temp\uninstall.log"
        New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force -ErrorAction SilentlyContinue | Out-Null

        Write-Host "Trying password: $Password"
        $Args = "/X`"$ProductCode`" /qn /norestart /l*v `"$LogFile`" XPSWD=`"$Password`""
        $Result = Start-Process "msiexec.exe" -ArgumentList $Args -Wait -PassThru

        if ($Result.ExitCode -eq 0) {
            Write-Host "Uninstallation successful!" -ForegroundColor Green
            New-Item -ItemType File -Path $UninstallFlagFile -Force | Out-Null
            Add-Content -Path $UninstallFlagFile -Value "Uninstallation successful with password: $Password"

            # Create a reboot pending flag only if no reboot flag exists
            if (-not (Test-Path $RebootFlagFile)) {
                $SystemUptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
                Set-Content -Path $RebootFlagFile -Value $SystemUptime
                Write-Host "Reboot flag created at: $RebootFlagFile. Prompting user to reboot..." -ForegroundColor Yellow
                Show-RebootPrompt
                exit
            }
        } else {
            Write-Host "Uninstallation failed." -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "Forcepoint DLP Endpoint not found."
    }
}

# Continue with the installation process only if uninstallation was successful or skipped
if ($UninstallationSkipped -or (Test-Path $UninstallFlagFile)) {
    $InstallFile = "C:\Temp\FORCEPOINT-ONE-ENDPOINT-x64.exe"
    $LogFile = "C:\Temp\Installation.log"

    if (Test-Path $InstallFile) {
        Get-Process | Where-Object { $_.Name -like "*Forcepoint*" -or $_.Name -like "*msiexec*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        $InstallArgs = '/v"/qn /norestart XPSWDPXY=<Password> WSCONTEXT=<Insert>"'
        $Result = Start-Process -FilePath $InstallFile -ArgumentList $InstallArgs -Wait -PassThru

        if ($Result.ExitCode -eq 0) {
            Write-Host "Installation completed successfully." -ForegroundColor Green
            New-Item -ItemType File -Path $InstallFlagFile -Force | Out-Null
            Add-Content -Path $InstallFlagFile -Value "Installation completed successfully."
        } elseif ($Result.ExitCode -eq 3010) {
            Write-Host "Installation completed but requires a reboot." -ForegroundColor Yellow
        } else {
            Write-Host "Installation failed. Exit Code: $($Result.ExitCode)" -ForegroundColor Red
        }
    } else {
        Write-Host "Installation file not found at: $InstallFile" -ForegroundColor Red
    }
}
# Change directory to Forcepoint Endpoint folder
Set-Location -Path "C:\Program Files\Websense\Websense Endpoint"
.\WDEUtil.exe -stop all -password "Password"
sleep 20
.\WDEUtil.exe -start all -password "Password"
