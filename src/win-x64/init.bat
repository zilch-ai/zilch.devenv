:: ======================================================================
:: Initialize the development environment for Windows x64
:: - Enable ANSI console if need
:: - Install scoop if not exist (https://scoop.sh/)
:: - Install WSL2 if need
:: - Detect if bash (WSL2 recommended) is ready
:: - Create DevEnv shortcut if need
:: NOTE: Run this script as administrator
:: ======================================================================
@ECHO OFF
CD %~dp0
CHCP 65001 >nul

REM Failfast if not running in administator mode
POWERSHELL -ExecutionPolicy Bypass -file %~dp0.system/check.ps1 -instruction "NET SESSION" -prompt "Check if running in administator mode..."
IF ERRORLEVEL 1 (
    POWERSHELL -Command "Write-Host 'ERROR: Please DO run init.bat as administrator.' -ForegroundColor Red"
    ECHO.
    ECHO See detailed instructions in the README.md file below:
    POWERSHELL -Command "Write-Host 'https://github.com/zilch-ai/zilch.devenv/blob/main/win-x64/README.md' -ForegroundColor Green"
    ECHO.
    ECHO Press any key to exit...
    PAUSE >nul
    EXIT /b %ERRORLEVEL%
)

REM Enable ANSI console if need
POWERSHELL -ExecutionPolicy Bypass -file %~dp0.system/check.ps1 -instruction "REG query 'HKCU\Console' /v VirtualTerminalLevel" -prompt "Check if ANSI console is enabled..."
IF ERRORLEVEL 1 (
    ECHO Enable ANSI console...
    REG add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f
    SET ANSI=1
    ECHO ANSI console enabled.
    ECHO.

    ECHO ANSI console will take effect after restarting the command prompt.
    ECHO We will restart the command prompt for you automatically.
    ECHO.
    ECHO Press any key to continue...
    PAUSE >nul
    ECHO.

    ECHO %* | findstr /i "--restarted" >nul 2>&1
    IF ERRORLEVEL 1 (
        START "" "%COMSPEC%" /k "%~f0" %* --restarted
        EXIT /b 0
    )
) ELSE (
    FOR /f "tokens=3" %%A IN ('reg query "HKCU\Console" /v VirtualTerminalLevel ^| find "REG_DWORD"') DO (
        IF not "%%A"=="0x1" (
            ECHO Registry key HKCU\Console\VirtualTerminalLevel is not enabled.
            SET ANSI=0
        )
    )
)

REM Say hi
SET HI=%USERNAME%@%COMPUTERNAME%
ECHO.
ECHO Hi, [32m%HI%[0m.
ECHO Let's get started to initialize the development environment.
ECHO.

REM Install scoop if need
POWERSHELL -ExecutionPolicy Bypass -file %~dp0.system/check.ps1 -cmd -instruction "WHERE scoop" -prompt "Check if scoop is ready..."
IF ERRORLEVEL 1 (
    ECHO Scoop is not installed.
    ECHO Installing scoop...
    POWERSHELL -ExecutionPolicy Bypass -file ./.system/scoop.ps1
    IF ERRORLEVEL 1 (
        ECHO [31mERROR:[0m PowerShell script failed with exit code %ERRORLEVEL%.
        ECHO Stopping execution due to error.
        ECHO.
        ECHO Press any key to exit...
        PAUSE >nul
        ECHO.
        EXIT /b %ERRORLEVEL%
    )
    ECHO Scoop installed.
    ECHO.
)

REM Install WSL2 if need
ECHO %* | findstr /i "wsl" >nul 2>&1
IF NOT ERRORLEVEL 1 (
    POWERSHELL -ExecutionPolicy Bypass -file %~dp0.system/check.ps1 -instruction "wsl --list --quiet" -prompt "Check if WSL2 is ready..."
    IF ERRORLEVEL 1 (
        CALL ./.system/wsl2.bat
        IF ERRORLEVEL 1 (
            ECHO [31mERROR:[0m Failed to install WSL2.
            ECHO Stopping execution due to error.
            ECHO.
            ECHO Press any key to exit...
            PAUSE >nul
            ECHO.
            EXIT /b %ERRORLEVEL%
        )
    )
)

REM Detect if bash (WSL2 recommended) is ready
POWERSHELL -ExecutionPolicy Bypass -file %~dp0.system/check.ps1 -cmd -instruction "WHERE bash" -prompt "Check if bash is ready..."
IF ERRORLEVEL 1 (
    ECHO Please install Git Bash or WSL2 to continue.
    ECHO.
    ECHO Press any key to exit...
    PAUSE >nul
    ECHO.
    EXIT /b %ERRORLEVEL%
)

REM Create DevEnv shortcut if need
SET SHORTCUT="%USERPROFILE%\Desktop\DevEnv.lnk"
IF NOT EXIST %SHORTCUT% (
    ECHO DevEnv shortcut not found on the desktop.
    ECHO Creating DevEnv shortcut...
    SET WORKING_DIR=%~dp0
    SET ICON=%~dp0devenv.ico
    POWERSHELL -ExecutionPolicy Bypass -file "%~dp0\.system\shortcut.ps1" -shortcut DevEnv -target "%~dp0devenv.bat" -location %~dp0 -icon "%ICON%" -admin
    IF ERRORLEVEL 1 (
        ECHO [31mERROR:[0m PowerShell script failed with exit code %ERRORLEVEL%.
        ECHO Stopping execution due to error.
        EXIT /b %ERRORLEVEL%
    )
    ECHO Shortcut created.
    ECHO.
)

REM Say good bye
ECHO.
ECHO The development environment is ready.
ECHO Please double-click the [32mDevEnv[0m shortcut on the desktop to start the development environment.
ECHO.
ECHO See detailed instructions in the README.md file below:
ECHO https://github.com/zilch-ai/zilch.devenv/blob/main/win-x64/README.md
ECHO.
ECHO Press any key to exit...
PAUSE >nul

REM Exit safely with restarting detected (avoid recursive context on exit)
IF "%~1" == "restarted" (
    EXIT
) ELSE (
    EXIT /b 0
)
