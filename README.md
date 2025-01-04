# ForcepointEndpointDeployment
Administrators can download and install new Forcepoint agents using a Powershell starting script. This script will assist you in installing the new agent and removing the old one.  

# Forcepoint One Endpoint Deployment Script

This PowerShell script automates the process of uninstalling, downloading, and installing the Forcepoint One Endpoint application. It includes mechanisms for managing reboots, verifying dependencies, and ensuring a smooth transition for the endpoint software.

## Features

- Checks for existing installation and skips reinstallation if already installed.
- Handles reboot requirements and prompts the user to reboot the system.
- Automates the uninstallation of existing Forcepoint DLP Endpoint installations.
- Downloads the installer from a specified URL if not already present.
- Starts and stops Forcepoint services using `WDEUtil.exe`.

## Prerequisites

- **PowerShell**: This script requires Windows PowerShell with administrative privileges.
- **Dependencies**: Ensure the following are accessible:
  - `Invoke-WebRequest` cmdlet (for file download).
  - Write permissions to the target paths.
- **Forcepoint Admin Password**: Ensure the correct password is included in the script for uninstall and service operations.

## Installation

1. Clone or download this repository.
2. Update the script with your custom details:
   - Replace `URL` with the download link for the installer.
   - Replace `Password` with the admin password required for Forcepoint operations.
   - Update paths as necessary.
3. Open a PowerShell terminal with administrative privileges.

## Usage

1. Save the script to your system.
2. Run the script using:
   ```powershell
   .\ForcepointEndpointDeployment.ps1
The script will:
Check for existing installation success or pending reboot flags.
Uninstall any existing Forcepoint DLP Endpoint installations.
Download and install the Forcepoint One Endpoint software.
Prompt for a reboot if required.
File Paths
Installer Download Path: C:\Temp\FORCEPOINT-ONE-ENDPOINT-x64.exe
Uninstall Success Flag: C:\Temp\UninstallSuccess.flag
Install Success Flag: C:\Temp\InstallSuccess.flag
Reboot Pending Flag: C:\Temp\RebootPending.flag
Logging
Uninstall Log: C:\Temp\uninstall.log
Install Log: C:\Temp\Installation.log
Notes
Ensure you have write permissions to the C:\Temp directory.
Modify the paths in the script if a different directory structure is preferred.
The script stops and restarts Forcepoint services after installation for proper functionality.
License
This project is licensed under the MIT License.

Author
Created by Sreerag For questions or contributions, contact me at [Your GitHub Profile Link].

Disclaimer: Use this script responsibly. Verify its behavior in a testing environment before deploying it in production.


