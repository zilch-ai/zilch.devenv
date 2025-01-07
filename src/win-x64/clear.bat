REM ======================================================================
REM Remove the impact of system changes in init.bat for debugging purposes
REM ======================================================================

@ECHO OFF
CD %~dp0
CHCP 65001 >nul

REM Failfast if running not in administator mode
NET SESSION >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO Please DO run clear.bat as administrator.
    ECHO See detailed instructions in the README.md file below:
    ECHO https://github.com/zilch-ai/zilch.devenv/blob/main/win-x64/README.md
    ECHO.
    ECHO Press any key to exit...
    PAUSE >nul
    EXIT /b %ERRORLEVEL%
)

REM Ask user if they want to continue with the cleanup process
ECHO This script will perform the following actions:
ECHO - Delete the shortcut link
ECHO - Clear the icon cache
ECHO - Disable ANSI console support
ECHO.
ECHO Are you sure you want to continue with these actions? (y/n)
SET /P confirm_clear=
IF /I "%confirm_clear%" NEQ "Y" (
    ECHO Operation cancelled. Exiting...
    EXIT /b
)

REM Clear the shortcut link
ECHO Clear the shortcut link...
CD /d %userprofile%\Desktop
DEL DevEnv.lnk
ECHO.

REM Clear the icon cache
ECHO Clear the icon cache...
TASKKILL /f /im explorer.exe
CD /d %userprofile%\AppData\Local
DEL IconCache.db /a
DEL %userprofile%\AppData\Local\Microsoft\Windows\Explorer\iconcache* /a /q
START explorer.exe
ECHO.

REM Disable ANSI console
ECHO Disable ANSI console...
REG delete "HKCU\Console" /v VirtualTerminalLevel /f
ECHO.

REM Reset the current directory
ECHO Reset the current directory
CD %~dp0
ECHO.
