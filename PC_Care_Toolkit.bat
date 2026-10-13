@echo off
rem ======================================================================
rem  WINDOWS PC CARE TOOLKIT  (Windows 10 / Windows 11)
rem ----------------------------------------------------------------------
rem  A safe, transparent maintenance toolkit. It uses only built-in
rem  Windows tools (PowerShell, DISM, SFC, ipconfig, chkdsk, cleanmgr...).
rem
rem  DESIGN RULES
rem   - Never deletes personal files, Downloads, Desktop, Documents,
rem     Pictures, Videos, browser profiles, passwords or installed apps.
rem   - Never disables Defender, Firewall, Windows Update or services.
rem   - Never edits the registry (it only EXPORTS keys as backups).
rem   - Asks for confirmation before anything that changes the system.
rem   - Never reboots the computer by itself.
rem   - Sends nothing online (only ping / DNS tests for diagnostics).
rem
rem  Logs and backups are stored in:  %USERPROFILE%\PCCare
rem ======================================================================

setlocal EnableExtensions EnableDelayedExpansion
title Windows PC Care Toolkit
cd /d "%~dp0" 2>nul

rem ---------------------------------------------------------------------
rem  USER SETTING: set to 0 if you see strange characters instead of colors
rem ---------------------------------------------------------------------
set "USE_COLOR=1"

rem ---------------------------------------------------------------------
rem  1. ADMINISTRATOR CHECK + AUTOMATIC ELEVATION
rem     "fltmc" only succeeds when the process is elevated.
rem ---------------------------------------------------------------------
fltmc >nul 2>&1
if errorlevel 1 (
    echo Administrator privileges are required. Requesting elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    if errorlevel 1 (
        echo.
        echo Elevation was cancelled or failed.
        echo Right-click this file and choose "Run as administrator".
        pause
    )
    exit /b
)

rem PowerShell is used for information gathering - make sure it exists.
where powershell >nul 2>&1
if errorlevel 1 (
    echo PowerShell was not found. This toolkit requires Windows 10 or 11.
    pause
    exit /b 1
)

rem ---------------------------------------------------------------------
rem  2. FOLDERS, LOG FILES, COLORS
rem ---------------------------------------------------------------------
set "BASEDIR=%USERPROFILE%\PCCare"
set "LOGDIR=%BASEDIR%\Logs"
set "BACKUPDIR=%BASEDIR%\Backups"
if not exist "%LOGDIR%"    mkdir "%LOGDIR%"    >nul 2>&1
if not exist "%BACKUPDIR%" mkdir "%BACKUPDIR%" >nul 2>&1

for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"
set "LOGFILE=%LOGDIR%\PCCare_%STAMP%.log"
set "SUMFILE=%LOGDIR%\PCCare_%STAMP%_summary.txt"
set "WORKFILE=%BASEDIR%\work.tmp"
set "SFCFILE=%BASEDIR%\sfc_output.tmp"

set "C_G=" & set "C_R=" & set "C_Y=" & set "C_C=" & set "C_X="
if "%USE_COLOR%"=="1" (
    for /f %%E in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%E"
)
if defined ESC (
    set "C_G=%ESC%[92m"
    set "C_R=%ESC%[91m"
    set "C_Y=%ESC%[93m"
    set "C_C=%ESC%[96m"
    set "C_X=%ESC%[0m"
)

rem Session state
set "RP_DONE=0"
set "TOTAL_KB=0"
set "R_TEMP=Not run"
set "R_DISK=Not run"
set "R_DISM=Not run"
set "R_SFC=Not run"
set "R_NET=Not run"
set "R_RP=Not created"
set "R_UPD=Not checked"

call :record INFO "Session started"
goto :MAIN_MENU


rem ======================================================================
rem  MAIN MENU
rem ======================================================================
:MAIN_MENU
cls
echo %C_C%========================================%C_X%
echo %C_C%       WINDOWS PC CARE TOOLKIT%C_X%
echo %C_C%========================================%C_X%
echo.
echo  [1]  Health Check
echo  [2]  Clean Junk ^& Temporary Files
echo  [3]  Windows Cache Cleanup
echo  [4]  DNS Cache Cleanup
echo  [5]  Repair Windows System Files
echo  [6]  Optimize Startup
echo  [7]  Network Optimization
echo  [8]  Disk Health ^& Cleanup
echo  [9]  Windows Update Check
echo  [10] Privacy Cleanup
echo  [11] Performance Maintenance
echo  [12] Create Restore Point
echo  [13] Run Full PC Care
echo  [14] View System Information
echo  [15] Exit
echo.
echo  Log folder: %LOGDIR%
echo.
set "CHOICE="
set /p "CHOICE=Select an option [1-15]: "

if "!CHOICE!"=="1"  call :health_check      & goto :BACK_TO_MENU
if "!CHOICE!"=="2"  call :junk_cleanup      & goto :BACK_TO_MENU
if "!CHOICE!"=="3"  call :cache_cleanup     & goto :BACK_TO_MENU
if "!CHOICE!"=="4"  call :dns_cleanup       & goto :BACK_TO_MENU
if "!CHOICE!"=="5"  call :repair_menu       & goto :BACK_TO_MENU
if "!CHOICE!"=="6"  call :startup_mgmt      & goto :BACK_TO_MENU
if "!CHOICE!"=="7"  call :network_menu      & goto :BACK_TO_MENU
if "!CHOICE!"=="8"  call :disk_menu         & goto :BACK_TO_MENU
if "!CHOICE!"=="9"  call :update_check_page & goto :BACK_TO_MENU
if "!CHOICE!"=="10" call :privacy_cleanup   & goto :BACK_TO_MENU
if "!CHOICE!"=="11" call :perf_maint        & goto :BACK_TO_MENU
if "!CHOICE!"=="12" call :restore_point_page & goto :BACK_TO_MENU
if "!CHOICE!"=="13" call :full_care         & goto :BACK_TO_MENU
if "!CHOICE!"=="14" call :sysinfo           & goto :BACK_TO_MENU
if "!CHOICE!"=="15" goto :EXIT_TOOL

echo.
echo %C_Y%Invalid choice. Please enter a number from 1 to 15.%C_X%
timeout /t 2 >nul
goto :MAIN_MENU

:BACK_TO_MENU
echo.
echo Press any key to return to the main menu...
pause >nul
goto :MAIN_MENU

:EXIT_TOOL
cls
call :banner "SESSION SUMMARY"
echo Actions performed during this session:
echo.
if exist "%SUMFILE%" (type "%SUMFILE%") else (echo   No actions were recorded.)
echo.
echo Detailed log: %LOGFILE%
echo.
echo Thank you for using the Windows PC Care Toolkit.
pause
exit /b 0


rem ======================================================================
rem  HELPER SUBROUTINES (output, logging, confirmation)
rem ======================================================================

:banner
echo %C_C%========================================%C_X%
echo %C_C%  %~1%C_X%
echo %C_C%========================================%C_X%
echo.
exit /b 0

:ok
echo %C_G%[ OK ]%C_X% %~1
>>"%LOGFILE%" echo [%date% %time%] OK   %~1
exit /b 0

:fail
echo %C_R%[FAIL]%C_X% %~1
>>"%LOGFILE%" echo [%date% %time%] FAIL %~1
exit /b 0

:warn
echo %C_Y%[WARN]%C_X% %~1
>>"%LOGFILE%" echo [%date% %time%] WARN %~1
exit /b 0

:info
echo %C_C%[INFO]%C_X% %~1
>>"%LOGFILE%" echo [%date% %time%] INFO %~1
exit /b 0

:skip
echo %C_Y%[SKIP]%C_X% %~1
>>"%LOGFILE%" echo [%date% %time%] SKIP %~1
exit /b 0

:step
echo.
echo %C_C%--- %~1 ---%C_X%
exit /b 0

rem  :record STATUS "message"  -> adds a line to the session summary file
:record
>>"%SUMFILE%" echo [%~1] %~2
exit /b 0

rem  :confirm "Question"  -> sets CONFIRMED=1 (yes) or 0 (no)
:confirm
set "CONFIRMED=0"
choice /c YN /n /m "%~1 [Y/N]: "
if errorlevel 1 if not errorlevel 2 set "CONFIRMED=1"
exit /b 0

rem  :fmtkb NUMBER_OF_KB -> sets FMT to a readable "x.y MB" string
:fmtkb
set /a "_m=%~1/1024"
set /a "_d=(%~1%%1024)*10/1024"
set "FMT=%_m%.%_d% MB"
exit /b 0

rem  :disk_free -> sets DISK_FREE_GB and DISK_TOTAL_GB for the system drive
:disk_free
set "DISK_FREE_GB=?"
set "DISK_TOTAL_GB=?"
powershell -NoProfile -Command "$d=Get-CimInstance Win32_LogicalDisk -Filter ('DeviceID=''%SystemDrive%'''); '{0} {1}' -f [math]::Round($d.FreeSpace/1GB,2),[math]::Round($d.Size/1GB,2)" > "%WORKFILE%" 2>nul
for /f "usebackq tokens=1,2" %%A in ("%WORKFILE%") do (
    set "DISK_FREE_GB=%%A"
    set "DISK_TOTAL_GB=%%B"
)
exit /b 0

rem  :clean_path "Label" "Folder" "Filter"
rem  Deletes the CONTENTS of a known-safe folder (files in use are skipped
rem  silently) and reports the space freed. Adds to TOTAL_KB.
:clean_path
set "CP_LABEL=%~1"
set "CP_PATH=%~2"
set "CP_FILTER=%~3"
if "%CP_FILTER%"=="" set "CP_FILTER=*"
set "CP_KB=0"

rem Safety allow-list: the path must look like a temp / cache / report folder.
echo "%CP_PATH%"| findstr /i /c:"Temp" /c:"Cache" /c:"WER" /c:"CrashDumps" /c:"Recent" /c:"Explorer" >nul
if errorlevel 1 (
    call :fail "%CP_LABEL%: refused - path is not on the safe list."
    exit /b 1
)
if not exist "%CP_PATH%\" (
    call :skip "%CP_LABEL%: folder not found, nothing to do."
    exit /b 0
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%CP_PATH%'; $f='%CP_FILTER%'; $m={ [long]((Get-ChildItem -LiteralPath $p -Filter $f -Recurse -Force -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum) }; $b=& $m; Get-ChildItem -LiteralPath $p -Filter $f -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue; $a=& $m; $d=$b-$a; if($d -lt 0){$d=0}; [long]($d/1KB)" > "%WORKFILE%" 2>nul
set /p CP_KB=<"%WORKFILE%"
echo %CP_KB%| findstr /r "^[0-9][0-9]*$" >nul || set "CP_KB=0"
set /a TOTAL_KB+=CP_KB
call :fmtkb %CP_KB%
call :ok "%CP_LABEL%: freed approx. %FMT% (files in use were skipped)"
exit /b 0


rem ======================================================================
rem  1. HEALTH CHECK
rem ======================================================================
:health_check
cls
call :banner "SYSTEM HEALTH CHECK"
echo This option only READS basic system information. Nothing is changed
echo and nothing is sent anywhere.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor | Select-Object -First 1; $u=(Get-Date)-$o.LastBootUpTime; $t=[math]::Round($o.TotalVisibleMemorySize/1MB,2); $f=[math]::Round($o.FreePhysicalMemory/1MB,2); Write-Host ('  Windows         : {0} (version {1}, build {2})' -f $o.Caption,$o.Version,$o.BuildNumber); Write-Host ('  Computer name   : {0}' -f $env:COMPUTERNAME); Write-Host ('  CPU             : {0}' -f $c.Name.Trim()); Write-Host ('  RAM total       : {0} GB' -f $t); Write-Host ('  RAM available   : {0} GB' -f $f); Write-Host ('  Uptime          : {0} d {1} h {2} min' -f $u.Days,$u.Hours,$u.Minutes)"
call :disk_free
echo   System drive    : %SystemDrive%  ^(%DISK_FREE_GB% GB free of %DISK_TOTAL_GB% GB^)

rem Activation status (read-only; the product key is never displayed)
powershell -NoProfile -Command "$l=Get-CimInstance SoftwareLicensingProduct -Filter 'ApplicationId=''55c92734-d682-4d71-983e-d6ec3f16059f'' AND PartialProductKey IS NOT NULL' -EA SilentlyContinue | Select-Object -First 1; if($l -and $l.LicenseStatus -eq 1){$s='Licensed (activated)'}elseif($l){$s='Not fully activated (status '+$l.LicenseStatus+')'}else{$s='Could not be determined'}; Write-Host ('  Activation      : {0}' -f $s)"

ping -n 1 -w 2000 1.1.1.1 | find "TTL=" >nul
if errorlevel 1 (echo   Network         : No internet reply ^(offline or ICMP blocked^)) else (echo   Network         : Online ^(internet reachable^))
echo   Administrator   : Yes ^(running elevated^)
echo.
call :record INFO "Health check viewed"
exit /b 0


rem ======================================================================
rem  2. CLEAN JUNK & TEMPORARY FILES
rem ======================================================================
:junk_cleanup
cls
call :banner "CLEAN JUNK AND TEMPORARY FILES"
echo WHAT THIS DOES - removes only temporary files that Windows and apps
echo recreate when needed:
echo   - User TEMP folder
echo   - Windows TEMP folder
echo   - Thumbnail cache files (rebuilt automatically)
echo   - Windows Error Reporting temporary files
echo   - Recycle Bin (asked separately, cannot be undone)
echo.
echo WHAT IS NEVER TOUCHED - Documents, Desktop, Downloads, Pictures,
echo Videos, browser profiles, installed programs and their settings.
echo Files that are currently in use are skipped.
echo.
call :confirm "Clean temporary files now?"
if not "%CONFIRMED%"=="1" (
    call :skip "Temporary file cleanup cancelled."
    call :record SKIP "Junk cleanup cancelled"
    exit /b 0
)
call :do_junk
echo.
call :recycle_bin
exit /b 0

rem  Core temp cleaning, also used by Full PC Care and Performance Maintenance
:do_junk
set "JUNK_START=%TOTAL_KB%"
call :clean_path "User TEMP folder"            "%TEMP%"                                           "*"
call :clean_path "Windows TEMP folder"         "%SystemRoot%\Temp"                                "*"
call :clean_path "Thumbnail cache"             "%LOCALAPPDATA%\Microsoft\Windows\Explorer"        "thumbcache_*.db"
call :clean_path "Error reports (user)"        "%LOCALAPPDATA%\Microsoft\Windows\WER"             "*"
call :clean_path "Error reports (system temp)" "%ProgramData%\Microsoft\Windows\WER\Temp"        "*"
set /a "RUN_KB=TOTAL_KB-JUNK_START"
call :fmtkb %RUN_KB%
set "R_TEMP=%FMT%"
echo.
call :ok "Total temporary files cleaned: approx. %FMT%"
call :record OK "Temporary files cleaned: approx. %FMT%"
exit /b 0

rem  Recycle Bin - only after explicit confirmation
:recycle_bin
echo The Recycle Bin holds files you deleted earlier. Emptying it is PERMANENT.
call :confirm "Empty the Recycle Bin?"
if not "%CONFIRMED%"=="1" (
    call :skip "Recycle Bin left untouched."
    exit /b 0
)
set "RB_KB=0"
powershell -NoProfile -Command "$m={[long]((Get-ChildItem -LiteralPath '%SystemDrive%\$Recycle.Bin' -Recurse -Force -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum)}; $b=& $m; Clear-RecycleBin -Force -EA SilentlyContinue; $a=& $m; $d=$b-$a; if($d -lt 0){$d=0}; [long]($d/1KB)" > "%WORKFILE%" 2>nul
set /p RB_KB=<"%WORKFILE%"
echo %RB_KB%| findstr /r "^[0-9][0-9]*$" >nul || set "RB_KB=0"
set /a TOTAL_KB+=RB_KB
call :fmtkb %RB_KB%
call :ok "Recycle Bin emptied (approx. %FMT% on the system drive)."
call :record OK "Recycle Bin emptied: approx. %FMT%"
exit /b 0


rem ======================================================================
rem  3. WINDOWS CACHE CLEANUP
rem ======================================================================
:cache_cleanup
cls
call :banner "WINDOWS CACHE CLEANUP"
echo WHAT THIS DOES - clears caches that Windows rebuilds automatically:
echo   - Internet cache (INetCache) used by Windows components
echo   - DirectX shader cache (first game launch afterwards may be slower)
echo   - Crash dump files of apps (user level)
echo   - Windows Error Reporting queue and archive
echo   - Delivery Optimization cache (Windows Update peer cache)
echo.
echo NOT TOUCHED - the Windows Update download store (SoftwareDistribution),
echo system files, drivers, and anything personal.
echo.
call :confirm "Clean these Windows caches now?"
if not "%CONFIRMED%"=="1" (
    call :skip "Cache cleanup cancelled."
    call :record SKIP "Windows cache cleanup cancelled"
    exit /b 0
)
set "CACHE_START=%TOTAL_KB%"
call :clean_path "Internet cache"        "%LOCALAPPDATA%\Microsoft\Windows\INetCache"                "*"
call :clean_path "DirectX shader cache"  "%LOCALAPPDATA%\D3DSCache"                                  "*"
call :clean_path "App crash dumps"       "%LOCALAPPDATA%\CrashDumps"                                 "*"
call :clean_path "Error report queue"    "%ProgramData%\Microsoft\Windows\WER\ReportQueue"           "*"
call :clean_path "Error report archive"  "%ProgramData%\Microsoft\Windows\WER\ReportArchive"         "*"

powershell -NoProfile -Command "try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (call :warn "Delivery Optimization cache: could not be cleared (command unavailable or in use).") else (call :ok "Delivery Optimization cache cleared.")

set /a "RUN_KB=TOTAL_KB-CACHE_START"
call :fmtkb %RUN_KB%
echo.
call :ok "Total cache data cleaned: approx. %FMT% (plus Delivery Optimization)"
call :record OK "Windows caches cleaned: approx. %FMT%"
exit /b 0


rem ======================================================================
rem  4. DNS CACHE CLEANUP
rem ======================================================================
:dns_cleanup
cls
call :banner "DNS CACHE CLEANUP"
echo WHAT THIS DOES - clears the local DNS resolver cache (ipconfig /flushdns),
echo which can fix "site not found" problems after network changes.
echo It does NOT change your DNS servers.
echo.
call :flush_dns
echo.
call :info "Current DNS configuration:"
call :show_dns
echo.
call :info "Testing connectivity..."
call :net_test
exit /b 0

:flush_dns
ipconfig /flushdns >nul 2>&1
if errorlevel 1 (
    call :fail "DNS cache could not be flushed."
    call :record FAIL "DNS cache flush"
) else (
    call :ok "DNS resolver cache flushed."
    call :record OK "DNS cache flushed"
)
exit /b 0

:show_dns
powershell -NoProfile -Command "Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses} | ForEach-Object { Write-Host ('  {0,-28} {1}' -f $_.InterfaceAlias,($_.ServerAddresses -join ', ')) }"
exit /b 0

rem  :net_test -> pings gateway + internet and tests DNS name resolution
:net_test
set "NT_GW=No gateway found"
set "NT_INT=FAIL"
set "NT_DNS=FAIL"
set "GW="
powershell -NoProfile -Command "$g=(Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway} | Select-Object -First 1).IPv4DefaultGateway.NextHop; if($g){$g}" > "%WORKFILE%" 2>nul
set /p GW=<"%WORKFILE%"
if defined GW goto :nt_gateway
call :warn "No default gateway found - the local network may be disconnected."
goto :nt_external
:nt_gateway
call :info "Pinging default gateway %GW% ..."
ping -n 2 -w 2000 %GW% | find "TTL=" >nul
if errorlevel 1 (set "NT_GW=FAIL" & call :fail "Gateway %GW% did not respond.") else (set "NT_GW=OK" & call :ok "Gateway %GW% responded.")
:nt_external
call :info "Pinging external address 1.1.1.1 ..."
ping -n 2 -w 2000 1.1.1.1 | find "TTL=" >nul
if errorlevel 1 (set "NT_INT=FAIL" & call :fail "No reply from 1.1.1.1 (internet may be down or ICMP blocked).") else (set "NT_INT=OK" & call :ok "Internet address responded.")
call :info "Testing DNS name resolution (www.microsoft.com) ..."
powershell -NoProfile -Command "try { Resolve-DnsName www.microsoft.com -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (set "NT_DNS=FAIL" & call :fail "DNS name resolution failed.") else (set "NT_DNS=OK" & call :ok "DNS name resolution works.")
set "R_NET=Gateway: %NT_GW% / Internet: %NT_INT% / DNS: %NT_DNS%"
call :record INFO "Network test - %R_NET%"
exit /b 0


rem ======================================================================
rem  5. REPAIR WINDOWS SYSTEM FILES (DISM + SFC)
rem ======================================================================
:repair_menu
cls
call :banner "REPAIR WINDOWS SYSTEM FILES"
echo These are Microsoft's own repair tools. They can take 10-30 minutes.
echo Please do NOT close this window or turn off the PC while they run.
echo.
echo  [1] DISM CheckHealth    (quick, read-only check)
echo  [2] DISM ScanHealth     (deeper read-only scan)
echo  [3] DISM RestoreHealth  (repairs the component store; may need internet)
echo  [4] SFC /scannow        (scans and repairs protected system files)
echo  [5] Run all in order (1, 2, 4)  - read-only DISM checks, then SFC
echo  [0] Back to main menu
echo.
set "RCH="
set /p "RCH=Select an option: "
if "!RCH!"=="1" call :dism_run CheckHealth & goto :repair_done
if "!RCH!"=="2" call :dism_run ScanHealth  & goto :repair_done
if "!RCH!"=="3" goto :repair_restore
if "!RCH!"=="4" goto :repair_sfc
if "!RCH!"=="5" goto :repair_all
if "!RCH!"=="0" exit /b 0
call :warn "Invalid choice."
:repair_done
echo.
pause
goto :repair_menu

:repair_restore
call :warn "RestoreHealth repairs Windows components. A restore point is recommended."
call :offer_restore
call :confirm "Run DISM RestoreHealth now?"
if "%CONFIRMED%"=="1" call :dism_run RestoreHealth
goto :repair_done

:repair_sfc
call :warn "SFC may replace damaged protected system files with good copies."
call :offer_restore
call :confirm "Run SFC /scannow now?"
if "%CONFIRMED%"=="1" call :sfc_run scannow
goto :repair_done

:repair_all
call :confirm "Run DISM CheckHealth, DISM ScanHealth and SFC now?"
if "%CONFIRMED%"=="1" (
    call :dism_run CheckHealth
    call :dism_run ScanHealth
    call :offer_restore
    call :sfc_run scannow
)
goto :repair_done

rem  :dism_run CheckHealth|ScanHealth|RestoreHealth
:dism_run
call :step "DISM /Online /Cleanup-Image /%~1"
call :info "Running. This can take several minutes - please wait..."
DISM /Online /Cleanup-Image /%~1 > "%WORKFILE%" 2>&1
set "DISM_RC=%errorlevel%"
type "%WORKFILE%"
if not "%DISM_RC%"=="0" (
    set "R_DISM=FAILED (error code %DISM_RC%)"
    call :fail "DISM %~1 failed with error code %DISM_RC%."
    call :record FAIL "DISM %~1 - error code %DISM_RC%"
    exit /b 1
)
findstr /i /c:"No component store corruption detected" "%WORKFILE%" >nul
if not errorlevel 1 (
    set "R_DISM=No component store corruption detected"
    call :ok "DISM %~1: no component store corruption detected."
    call :record OK "DISM %~1 - healthy"
    exit /b 0
)
findstr /i /c:"repairable" "%WORKFILE%" >nul
if not errorlevel 1 (
    set "R_DISM=Corruption found - repairable (run DISM RestoreHealth)"
    call :warn "DISM %~1: component store is repairable. Run RestoreHealth."
    call :record WARN "DISM %~1 - corruption repairable"
    exit /b 0
)
set "R_DISM=%~1 completed successfully"
call :ok "DISM %~1 completed (error code 0)."
call :record OK "DISM %~1 completed"
exit /b 0

rem  :sfc_run scannow|verifyonly
rem  Output is captured (SFC writes UTF-16) so the result can be interpreted.
:sfc_run
call :step "SFC /%~1"
call :info "Running System File Checker. Progress is not shown - this can take 10-20 minutes. Please wait..."
sfc /%~1 > "%SFCFILE%" 2>&1
powershell -NoProfile -Command "$t=Get-Content -LiteralPath '%SFCFILE%' -Encoding Unicode -Raw; if($t -notmatch 'Windows'){$t=Get-Content -LiteralPath '%SFCFILE%' -Raw}; $t=$t -replace '\s+',' '; if($t -match 'did not find any integrity violations'){exit 0}elseif($t -match 'successfully repaired'){exit 1}elseif($t -match 'unable to fix'){exit 2}elseif($t -match 'found integrity violations'){exit 3}else{exit 9}"
set "SFC_RC=%errorlevel%"
if "%SFC_RC%"=="0" (
    set "R_SFC=No integrity violations found"
    call :ok "SFC: no integrity violations found."
    call :record OK "SFC %~1 - no integrity violations"
    exit /b 0
)
if "%SFC_RC%"=="1" (
    set "R_SFC=Corrupt files found and repaired"
    call :ok "SFC: corrupt files were found and successfully repaired."
    call :record OK "SFC %~1 - corrupt files repaired"
    exit /b 0
)
if "%SFC_RC%"=="2" (
    set "R_SFC=Corrupt files found - could NOT repair some (see CBS.log)"
    call :fail "SFC found corrupt files it could not repair. Run DISM RestoreHealth, then SFC again."
    call :record FAIL "SFC %~1 - unable to repair some files"
    exit /b 1
)
if "%SFC_RC%"=="3" (
    set "R_SFC=Integrity violations found (verify-only, nothing repaired)"
    call :warn "SFC found integrity violations. Use Repair menu option 4 to repair them."
    call :record WARN "SFC %~1 - integrity violations found"
    exit /b 0
)
set "R_SFC=Completed - result could not be read automatically"
call :warn "SFC finished but the result text could not be interpreted (non-English Windows?)."
call :info "Details are in %windir%\Logs\CBS\CBS.log"
call :record WARN "SFC %~1 - result not interpreted"
exit /b 0


rem ======================================================================
rem  6. OPTIMIZE STARTUP  (view only - nothing is disabled by this script)
rem ======================================================================
:startup_mgmt
cls
call :banner "OPTIMIZE STARTUP"
echo Programs that start with Windows can slow down boot time. This script
echo only SHOWS them - it never disables anything automatically.
echo.
call :list_startup
echo.
echo HOW TO DISABLE AN ITEM YOURSELF (safe, reversible):
echo   Task Manager ^> Startup apps ^> right-click the item ^> Disable.
echo.
echo DO NOT disable: Windows Security / Microsoft Defender, graphics drivers
echo (NVIDIA / AMD / Intel), audio drivers (Realtek etc.), networking items,
echo or anything you do not recognise - look it up first.
echo.
echo  [1] Open Task Manager
echo  [2] Open Settings ^> Startup apps
echo  [0] Back
set "SCH="
set /p "SCH=Select an option: "
if "!SCH!"=="1" start "" taskmgr.exe
if "!SCH!"=="2" start "" ms-settings:startupapps
call :record INFO "Startup items viewed"
exit /b 0

:list_startup
call :info "Startup items registered with Windows (read-only list):"
powershell -NoProfile -Command "Get-CimInstance Win32_StartupCommand | Select-Object Name,Location,User | Format-Table -AutoSize | Out-String -Width 160 | Write-Host"
call :info "Task Manager may show additional items (Store apps, scheduled tasks)."
exit /b 0


rem ======================================================================
rem  7. NETWORK OPTIMIZATION (safe troubleshooting only)
rem ======================================================================
:network_menu
cls
call :banner "NETWORK MAINTENANCE"
echo Safe network troubleshooting. No advanced TCP/IP settings are changed.
echo.
echo  [1] Show IP configuration and DNS servers
echo  [2] Flush DNS cache
echo  [3] Release / renew DHCP lease  (brief disconnect)
echo  [4] Reset Winsock               (needs confirmation + reboot)
echo  [5] Test connectivity (gateway + internet + DNS)
echo  [6] Quick routine: 1 + 2 + 5
echo  [0] Back to main menu
echo.
set "NCH="
set /p "NCH=Select an option: "
if "!NCH!"=="1" call :net_show     & goto :network_done
if "!NCH!"=="2" call :flush_dns    & goto :network_done
if "!NCH!"=="3" call :net_renew    & goto :network_done
if "!NCH!"=="4" call :net_winsock  & goto :network_done
if "!NCH!"=="5" call :net_test     & goto :network_done
if "!NCH!"=="6" call :net_show & call :flush_dns & call :net_test & goto :network_done
if "!NCH!"=="0" exit /b 0
call :warn "Invalid choice."
:network_done
echo.
pause
goto :network_menu

:net_show
call :info "IP configuration:"
ipconfig
call :info "DNS servers in use:"
call :show_dns
call :record INFO "IP configuration viewed"
exit /b 0

:net_renew
echo This releases and renews your DHCP lease. Your connection will drop for
echo a few seconds. Do not use this over a remote session.
call :confirm "Release and renew the DHCP lease now?"
if not "%CONFIRMED%"=="1" (
    call :skip "DHCP renew cancelled."
    exit /b 0
)
ipconfig /release >nul 2>&1
ipconfig /renew   >nul 2>&1
if errorlevel 1 (
    call :fail "DHCP renew reported an error (static IP or no DHCP server?)."
    call :record FAIL "DHCP release/renew"
) else (
    call :ok "DHCP lease released and renewed."
    call :record OK "DHCP release/renew"
)
exit /b 0

:net_winsock
echo WHAT THIS DOES - resets the Winsock catalog to Windows defaults. It can
echo fix odd connection problems caused by broken network software.
echo A reboot is required afterwards. VPN/security software may need to be
echo reinstalled or repaired if it hooked into Winsock.
call :offer_restore
call :confirm "Reset Winsock now?"
if not "%CONFIRMED%"=="1" (
    call :skip "Winsock reset cancelled."
    exit /b 0
)
rem Backups BEFORE the change (registry export only - nothing is modified here)
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Winsock"  "%BACKUPDIR%\Winsock_%STAMP%.reg"  /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Winsock2" "%BACKUPDIR%\Winsock2_%STAMP%.reg" /y >nul 2>&1
netsh winsock show catalog > "%BACKUPDIR%\Winsock_catalog_%STAMP%.txt" 2>&1
call :info "Backups saved in %BACKUPDIR%"
netsh winsock reset
if errorlevel 1 (
    call :fail "Winsock reset failed."
    call :record FAIL "Winsock reset"
) else (
    call :ok "Winsock reset completed. Please restart the computer when convenient."
    call :record OK "Winsock reset (restart required)"
)
exit /b 0


rem ======================================================================
rem  8. DISK HEALTH & CLEANUP
rem ======================================================================
:disk_menu
cls
call :banner "DISK MAINTENANCE"
call :disk_show
echo.
echo  [1] Windows Storage settings (Storage Sense / cleanup recommendations)
echo  [2] Windows Disk Cleanup (cleanmgr - you choose what to delete)
echo  [3] Show TRIM status and disk health
echo  [4] Run SSD re-TRIM  (SSD only, safe, needs confirmation)
echo  [5] CHKDSK read-only scan
echo  [6] Schedule CHKDSK repair at next restart (needs confirmation)
echo  [0] Back to main menu
echo.
set "DCH="
set /p "DCH=Select an option: "
if "!DCH!"=="1" start "" ms-settings:storagesense & call :record INFO "Opened Storage settings" & goto :disk_done
if "!DCH!"=="2" goto :disk_cleanmgr
if "!DCH!"=="3" call :disk_trim   & goto :disk_done
if "!DCH!"=="4" call :disk_retrim & goto :disk_done
if "!DCH!"=="5" call :disk_chkdsk_scan & goto :disk_done
if "!DCH!"=="6" call :disk_chkdsk_schedule & goto :disk_done
if "!DCH!"=="0" exit /b 0
call :warn "Invalid choice."
:disk_done
echo.
pause
goto :disk_menu

:disk_cleanmgr
echo Disk Cleanup opens its own window. Review the checkboxes yourself;
echo nothing is deleted until you click OK.
set "SD=%SystemDrive:~0,1%"
start "" cleanmgr.exe /d %SD%
call :record INFO "Opened Disk Cleanup"
goto :disk_done

:disk_show
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { Write-Host ('  Drive {0}  capacity {1} GB  used {2} GB  free {3} GB' -f $_.DeviceID,[math]::Round($_.Size/1GB,1),[math]::Round(($_.Size-$_.FreeSpace)/1GB,1),[math]::Round($_.FreeSpace/1GB,1)) }"
exit /b 0

:disk_trim
call :info "TRIM status (DisableDeleteNotify = 0 means TRIM is ENABLED):"
fsutil behavior query DisableDeleteNotify
echo.
call :info "Physical disk type and health reported by Windows:"
powershell -NoProfile -Command "Get-PhysicalDisk | Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus | Format-Table -AutoSize | Out-String -Width 160 | Write-Host"
call :record INFO "TRIM status and disk health viewed"
exit /b 0

:disk_retrim
echo WHAT THIS DOES - asks Windows to re-TRIM the system drive (defrag /L).
echo It is only meaningful for SSDs and is the same task Windows schedules
echo itself. Hard drives are NOT defragmented by this script.
call :confirm "Run re-TRIM on %SystemDrive% now?"
if not "%CONFIRMED%"=="1" (
    call :skip "Re-TRIM cancelled."
    exit /b 0
)
defrag %SystemDrive% /L
if errorlevel 1 (
    call :fail "Re-TRIM failed or is not supported on this drive type."
    call :record FAIL "Re-TRIM"
) else (
    call :ok "Re-TRIM completed."
    call :record OK "Re-TRIM completed"
)
exit /b 0

:disk_chkdsk_scan
call :info "Running CHKDSK in read-only mode on %SystemDrive% (no repairs are made)..."
chkdsk %SystemDrive%
if errorlevel 1 (
    call :warn "CHKDSK reported a problem (exit code %errorlevel%). Consider scheduling a repair."
    set "R_DISK=CHKDSK reported issues"
    call :record WARN "CHKDSK read-only scan reported issues"
) else (
    call :ok "CHKDSK found no errors."
    set "R_DISK=CHKDSK found no errors"
    call :record OK "CHKDSK read-only scan clean"
)
exit /b 0

:disk_chkdsk_schedule
echo WHAT THIS DOES - marks %SystemDrive% for a full check and repair
echo (chkdsk /F) during the NEXT restart, before Windows loads. It can take
echo from several minutes to hours on large drives.
echo The computer is NOT restarted by this script.
echo To cancel the scheduled check later, run:  chkntfs /x %SystemDrive%
call :offer_restore
call :confirm "Schedule CHKDSK repair for the next restart?"
if not "%CONFIRMED%"=="1" (
    call :skip "CHKDSK repair not scheduled."
    exit /b 0
)
fsutil dirty set %SystemDrive% >nul 2>&1
if errorlevel 1 (
    call :fail "Could not schedule the disk check."
    call :record FAIL "CHKDSK schedule"
) else (
    call :ok "Disk check scheduled. It will run at the next restart."
    call :record OK "CHKDSK repair scheduled for next restart"
)
exit /b 0


rem ======================================================================
rem  9. WINDOWS UPDATE CHECK (read-only; Windows Update stays untouched)
rem ======================================================================
:update_check_page
cls
call :banner "WINDOWS UPDATE CHECK"
echo This shows the update status and can open the Windows Update page.
echo It never disables, resets or deletes any Windows Update component.
echo.
call :update_check
exit /b 0

:update_check
call :info "Windows Update service state (Stopped/Manual is normal when idle):"
powershell -NoProfile -Command "Get-Service wuauserv | Select-Object Status,StartType,DisplayName | Format-Table -AutoSize | Out-String -Width 160 | Write-Host"
call :info "Five most recently installed updates:"
powershell -NoProfile -Command "Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5 HotFixID,Description,InstalledOn | Format-Table -AutoSize | Out-String -Width 160 | Write-Host"
powershell -NoProfile -Command "if(Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'){exit 1}else{exit 0}"
if errorlevel 1 (
    set "R_UPD=A restart is pending to finish updates"
    call :warn "A restart is pending to finish installing updates."
) else (
    set "R_UPD=No pending restart detected"
    call :ok "No pending update restart detected."
)
call :confirm "Open the Windows Update settings page to check for updates?"
if "%CONFIRMED%"=="1" start "" ms-settings:windowsupdate
call :record INFO "Windows Update status checked - %R_UPD%"
exit /b 0


rem ======================================================================
rem  10. PRIVACY CLEANUP
rem ======================================================================
:privacy_cleanup
cls
call :banner "PRIVACY CLEANUP"
echo Choose what to clean. Each item is asked separately.
echo.
echo NEVER deleted by this script: saved passwords, cookies, bookmarks,
echo login sessions, autofill data or browsing history. To remove those,
echo use your browser's own "Clear browsing data" dialog (Ctrl+Shift+Del).
echo.
set "PV_START=%TOTAL_KB%"

call :confirm "1/4  Clean temporary files (user and Windows TEMP)?"
if "%CONFIRMED%"=="1" (
    call :clean_path "User TEMP folder"    "%TEMP%"            "*"
    call :clean_path "Windows TEMP folder" "%SystemRoot%\Temp" "*"
)

echo.
echo Recent-file history: removes the shortcut list shown in File Explorer
echo quick access and jump lists. Your actual files are not touched.
call :confirm "2/4  Clear the Windows recent-files list?"
if "%CONFIRMED%"=="1" call :clean_path "Recent files list" "%APPDATA%\Microsoft\Windows\Recent" "*.lnk"

echo.
echo 3/4  Recycle Bin (permanent deletion):
call :recycle_bin

echo.
echo Browser cache: removes only cached web files (images, scripts) for the
echo DEFAULT profile of Chrome and Edge. Close your browsers first - files in
echo use are skipped. Cookies, passwords and history are NOT affected.
call :confirm "4/4  Clean Chrome and Edge cache?"
if "%CONFIRMED%"=="1" (
    call :clean_path "Chrome cache" "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\Cache_Data" "*"
    call :clean_path "Edge cache"   "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\Cache_Data" "*"
)

set /a "RUN_KB=TOTAL_KB-PV_START"
call :fmtkb %RUN_KB%
echo.
call :ok "Privacy cleanup finished. Total freed this run: approx. %FMT%"
call :record OK "Privacy cleanup finished: approx. %FMT%"
exit /b 0


rem ======================================================================
rem  11. PERFORMANCE MAINTENANCE
rem ======================================================================
:perf_maint
cls
call :banner "PERFORMANCE MAINTENANCE"
echo A safe routine that CHECKS and CLEANS - it makes no performance
echo "tweaks". It does not kill processes, "free" RAM, or change CPU,
echo power, pagefile or registry settings. Steps:
echo   1. Check available RAM and disk space
echo   2. DISM CheckHealth (read-only)
echo   3. List startup items (read-only)
echo   4. Check Windows Update status
echo   5. Clean temporary files        (asks first)
echo   6. Flush DNS cache
echo   7. SFC /verifyonly - file integrity check (read-only, no repairs)
echo.
call :confirm "Start Performance Maintenance?"
if not "%CONFIRMED%"=="1" (
    call :skip "Performance Maintenance cancelled."
    exit /b 0
)

call :step "1/7 Memory and disk space"
powershell -NoProfile -Command "$o=Get-CimInstance Win32_OperatingSystem; Write-Host ('  RAM available: {0} GB of {1} GB' -f [math]::Round($o.FreePhysicalMemory/1MB,2),[math]::Round($o.TotalVisibleMemorySize/1MB,2))"
call :disk_show
call :disk_free
set "PM_BEFORE=%DISK_FREE_GB%"

call :step "2/7 Windows component health"
call :dism_run CheckHealth

call :step "3/7 Startup items"
call :list_startup

call :step "4/7 Windows Update"
call :update_check

call :step "5/7 Temporary files"
call :confirm "Clean temporary files now?"
if "%CONFIRMED%"=="1" (call :do_junk) else (call :skip "Temporary file cleanup skipped.")

call :step "6/7 DNS cache"
call :flush_dns

call :step "7/7 System file integrity (verify only)"
call :sfc_run verifyonly

call :disk_free
echo.
call :ok "Performance Maintenance finished. Free space: %PM_BEFORE% GB before, %DISK_FREE_GB% GB after."
call :record OK "Performance Maintenance finished"
echo.
echo SUGGESTION: if boot time is slow, disable unneeded startup apps yourself
echo (menu option 6) and keep Windows and drivers up to date.
exit /b 0


rem ======================================================================
rem  12. RESTORE POINT
rem ======================================================================
:restore_point_page
cls
call :banner "CREATE RESTORE POINT"
echo Creating a restore point before system optimization is recommended.
echo.
echo WHAT THIS DOES - asks Windows to save a snapshot of system files and
echo settings so you can roll back from Control Panel ^> Recovery.
echo Personal files are not included in restore points.
echo Windows normally allows only one restore point per 24 hours.
echo.
call :confirm "Create a restore point now?"
if "%CONFIRMED%"=="1" (call :create_rp) else (call :skip "Restore point cancelled.")
exit /b 0

rem  :offer_restore -> offers a restore point before a risky action
:offer_restore
if "%RP_DONE%"=="1" exit /b 0
echo.
call :warn "This action changes system settings. A restore point is recommended first."
call :confirm "Create a restore point now?"
if "%CONFIRMED%"=="1" call :create_rp
echo.
exit /b 0

rem  :create_rp -> returns errorlevel 0 on verified success, 1 otherwise
:create_rp
set "RP_TRIED=0"
call :info "Creating a restore point (this can take up to a minute)..."
:create_rp_try
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $b=(Get-ComputerRestorePoint -EA SilentlyContinue | Sort-Object SequenceNumber -Descending | Select-Object -First 1).SequenceNumber; Checkpoint-Computer -Description 'PC Care Toolkit' -RestorePointType MODIFY_SETTINGS -WarningAction SilentlyContinue; $a=(Get-ComputerRestorePoint -EA SilentlyContinue | Sort-Object SequenceNumber -Descending | Select-Object -First 1).SequenceNumber; if($a -and $a -ne $b){exit 0}else{exit 3} } catch { $_.Exception.Message | Out-File -FilePath '%WORKFILE%' -Encoding ascii; exit 2 }"
set "RP_RC=%errorlevel%"
if "%RP_RC%"=="0" goto :rp_ok
if "%RP_RC%"=="3" goto :rp_skipped
goto :rp_error

:rp_ok
set "RP_DONE=1"
set "R_RP=Created and verified"
call :ok "Restore point created and verified."
call :record OK "Restore point created"
exit /b 0

:rp_skipped
set "R_RP=Not created (Windows allows one per 24 hours by default)"
call :warn "Windows did NOT create a new restore point - it limits creation to one every 24 hours."
call :info "Most recent existing restore point:"
powershell -NoProfile -Command "Get-ComputerRestorePoint | Sort-Object SequenceNumber -Descending | Select-Object -First 1 SequenceNumber,Description,CreationTime | Format-List | Out-String | Write-Host"
call :record SKIP "Restore point not created (24-hour limit or no change)"
exit /b 1

:rp_error
set "R_RP=FAILED"
call :fail "The restore point could NOT be created. Windows reported:"
if exist "%WORKFILE%" type "%WORKFILE%"
echo.
if "%RP_TRIED%"=="1" (
    call :record FAIL "Restore point creation failed"
    exit /b 1
)
call :warn "System Protection may be turned off for %SystemDrive%."
call :confirm "Turn on System Protection for %SystemDrive% and try again?"
if not "%CONFIRMED%"=="1" (
    call :record FAIL "Restore point failed - System Protection left unchanged"
    exit /b 1
)
set "RP_TRIED=1"
powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive '%SystemDrive%\' -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    call :fail "System Protection could not be enabled automatically."
    call :info "Open Start, type 'Create a restore point', select the drive and click Configure."
    call :record FAIL "Could not enable System Protection"
    exit /b 1
)
call :ok "System Protection enabled. Retrying..."
goto :create_rp_try


rem ======================================================================
rem  13. FULL PC CARE
rem ======================================================================
:full_care
cls
call :banner "FULL PC CARE"
echo This safe routine runs, in order:
echo   1. Check administrator privileges
echo   2. Display system information
echo   3. Create a restore point
echo   4. Check disk space
echo   5. Clean safe temporary files   (Recycle Bin is NOT emptied)
echo   6. Flush DNS cache
echo   7. DISM CheckHealth             (quick, read-only)
echo   8. SFC /scannow                 (can take 10-20 minutes)
echo   9. Check Windows Update
echo  10. Show the final status
echo.
echo Nothing personal is deleted and the computer is NOT restarted.
echo.
call :confirm "Start Full PC Care now?"
if not "%CONFIRMED%"=="1" (
    call :skip "Full PC Care cancelled."
    exit /b 0
)

set "R_TEMP=Not run" & set "R_DISK=Not run" & set "R_DISM=Not run"
set "R_SFC=Not run"  & set "R_NET=Not run"  & set "R_RP=Not created" & set "R_UPD=Not checked"
set "FC_START=%date% %time%"

call :step "1/10 Administrator check"
fltmc >nul 2>&1
if errorlevel 1 (
    call :fail "Not running as administrator. Aborting."
    exit /b 1
)
call :ok "Running with administrator privileges."

call :step "2/10 System information"
call :health_summary_only

call :step "3/10 Restore point"
call :create_rp
if not errorlevel 1 goto :fc_after_rp
call :warn "No new restore point was created."
call :confirm "Continue Full PC Care without a new restore point?"
if not "%CONFIRMED%"=="1" (
    call :info "Full PC Care stopped by the user."
    call :record SKIP "Full PC Care stopped - no restore point"
    exit /b 0
)
:fc_after_rp

call :step "4/10 Disk space (before)"
call :disk_free
set "FC_FREE_BEFORE=%DISK_FREE_GB%"
call :info "Free space on %SystemDrive%: %FC_FREE_BEFORE% GB of %DISK_TOTAL_GB% GB"

call :step "5/10 Temporary files"
call :do_junk

call :step "6/10 DNS cache"
call :flush_dns

call :step "7/10 DISM CheckHealth"
call :dism_run CheckHealth

call :step "8/10 SFC /scannow"
call :sfc_run scannow

call :step "9/10 Windows Update"
call :update_check

call :step "10/10 Final status"
call :disk_free
set "FC_FREE_AFTER=%DISK_FREE_GB%"
call :net_test

echo.
echo %C_C%========================================%C_X%
echo %C_C%          PC CARE COMPLETED%C_X%
echo %C_C%========================================%C_X%
echo.
echo   Temporary files cleaned : %R_TEMP%
echo   Disk space (free)       : %FC_FREE_BEFORE% GB before  /  %FC_FREE_AFTER% GB after
echo   Restore point           : %R_RP%
echo   DISM result             : %R_DISM%
echo   SFC result              : %R_SFC%
echo   Windows Update          : %R_UPD%
echo   Network test            : %R_NET%
echo.
echo   Operations that failed this session:
findstr /c:"[FAIL]" "%SUMFILE%" >nul 2>&1 && findstr /c:"[FAIL]" "%SUMFILE%" || echo     None
echo.
echo   Recommended next steps:
echo     - Restart the computer if Windows Update, SFC or Winsock asked for it.
echo     - If SFC could not repair files, run DISM RestoreHealth (menu 5), then SFC again.
echo     - Review startup apps in Task Manager (menu 6).
echo     - Keep Windows, drivers and your security software up to date.
echo.
echo   Started: %FC_START%    Finished: %date% %time%
echo   Log: %LOGFILE%
call :record OK "Full PC Care completed"
exit /b 0

rem  Compact system summary used by Full PC Care
:health_summary_only
powershell -NoProfile -ExecutionPolicy Bypass -Command "$o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor | Select-Object -First 1; $u=(Get-Date)-$o.LastBootUpTime; Write-Host ('  Windows : {0} (build {1})' -f $o.Caption,$o.BuildNumber); Write-Host ('  Computer: {0}' -f $env:COMPUTERNAME); Write-Host ('  CPU     : {0}' -f $c.Name.Trim()); Write-Host ('  RAM     : {0} GB free of {1} GB' -f [math]::Round($o.FreePhysicalMemory/1MB,2),[math]::Round($o.TotalVisibleMemorySize/1MB,2)); Write-Host ('  Uptime  : {0} d {1} h {2} min' -f $u.Days,$u.Hours,$u.Minutes)"
exit /b 0


rem ======================================================================
rem  14. SYSTEM INFORMATION  (read-only, nothing is sent anywhere)
rem ======================================================================
:sysinfo
cls
call :banner "SYSTEM INFORMATION"
echo Read-only. Nothing is stored online or sent anywhere. Serial numbers and
echo product keys are never displayed.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$o=Get-CimInstance Win32_OperatingSystem; $u=(Get-Date)-$o.LastBootUpTime; Write-Host ('  Windows edition : {0}' -f $o.Caption); Write-Host ('  Version / build : {0} / {1}' -f $o.Version,$o.BuildNumber); Write-Host ('  Architecture    : {0}' -f $o.OSArchitecture); Write-Host ('  Uptime          : {0} d {1} h {2} min' -f $u.Days,$u.Hours,$u.Minutes)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=Get-CimInstance Win32_Processor | Select-Object -First 1; Write-Host ('  CPU             : {0} ({1} cores, {2} threads)' -f $c.Name.Trim(),$c.NumberOfCores,$c.NumberOfLogicalProcessors); $r=(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory; Write-Host ('  RAM installed   : {0} GB' -f [math]::Round($r/1GB,1)); Get-CimInstance Win32_VideoController | ForEach-Object { Write-Host ('  GPU             : {0}' -f $_.Name) }; $b=Get-CimInstance Win32_BIOS; Write-Host ('  BIOS            : {0} {1}' -f $b.Manufacturer,$b.SMBIOSBIOSVersion); $m=Get-CimInstance Win32_BaseBoard; Write-Host ('  Motherboard     : {0} {1}' -f $m.Manufacturer,$m.Product)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_DiskDrive | ForEach-Object { Write-Host ('  Physical disk   : {0} ({1} GB)' -f $_.Model,[math]::Round($_.Size/1GB)) }; Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { Write-Host ('  Volume {0}       : {1} GB free of {2} GB' -f $_.DeviceID,[math]::Round($_.FreeSpace/1GB,1),[math]::Round($_.Size/1GB,1)) }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $ip=(Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -EA SilentlyContinue | Select-Object -First 1).IPAddress; Write-Host ('  Adapter         : {0} - {1} - IPv4 {2}' -f $_.Name,$_.InterfaceDescription,$ip) }"
echo.
echo A MAC address is only needed for things like router filtering.
call :confirm "Show MAC addresses of active adapters?"
if "%CONFIRMED%"=="1" powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { Write-Host ('  MAC ({0}) : {1}' -f $_.Name,$_.MacAddress) }"
call :record INFO "System information viewed"
exit /b 0
