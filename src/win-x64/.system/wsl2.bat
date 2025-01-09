:: ======================================================================
:: Install WSL2 with Ubuntu
:: - Enable ANSI console if need
:: - Install scoop if not exist (https://scoop.sh/)
:: - Create DevEnv shortcut if need
:: NOTE: Run this script as administrator
:: ======================================================================
@ECHO OFF

ECHO Check Virtualization is enabled in BIOS/UEFI... | set /p= <nul
wmic cpu get VirtualizationFirmwareEnabled | findstr /i "TRUE" >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO [31mFAILED:[0m
    EXIT /b %ERRORLEVEL%
) 
ECHO [32mOK[0m

ECHO Check if Hyper-V is enabled... | set /p= <nul
SET HYPERV=0
dism /online /get-features | findstr /i "Microsoft-Hyper-V" >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO [31mFAILED:[0m
    SET HYPERV=1
) ELSE (
    ECHO [32mOK[0m
)
IF %HYPERV% == 1 (
    ECHO Install Hyper-V...
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
    IF ERRORLEVEL 1 (
        ECHO [31mERROR:[0m Failed to enable Hyper-V.
        EXIT /b %ERRORLEVEL%
    )
    ECHO Hyper-V enabled successfully.
    ECHO Please [32mrestart[0m your system then rerun [32minit.bat[0m to continue.
    ECHO.
    ECHO Press any key to exit...
    PAUSE >nul
    EXIT /b 0
)

ECHO Install WSL2 with Ubuntu...
wsl --install >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO [31mERROR:[0m Failed to install WSL2.
    EXIT /b %ERRORLEVEL%
)
ECHO WSL2 installed successfully.
