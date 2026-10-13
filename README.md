# Windows PC Care Toolkit

A safe, transparent maintenance toolkit for Windows 10 and 11, written as a single `.bat` file.
It uses only built-in Windows tools (PowerShell, DISM, SFC, ipconfig, chkdsk, cleanmgr).

## Features
- Health check and system information (read-only)
- Temporary file, cache and privacy cleanup (confirmation required)
- DNS flush and network troubleshooting
- DISM and SFC system file repair
- Startup review (view only, you decide what to disable)
- Disk health, TRIM status and CHKDSK (repairs only after confirmation)
- Windows Update status check
- Restore point creation with verification
- Full PC Care routine with a final summary

## Safety
- Never deletes personal files, Downloads, browser profiles or installed apps
- Never disables Defender, Firewall, Windows Update or services
- Never edits the registry (only exports backups)
- Never reboots automatically and sends nothing online

## Usage
1. Download `PC_Care_Toolkit.bat`
2. Right-click it and choose **Run as administrator**
3. Pick an option from the menu

Logs and backups are saved to `%USERPROFILE%\PCCare`.

## Disclaimer
Provided as is, without warranty. Create a restore point before use and review the code first.

## License
MIT
