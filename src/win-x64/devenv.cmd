:: ======================================================================
:: Launches the development environment for the current project.
:: NOTE: All the necessary configurations are done in the `launch.sh` script.
:: ======================================================================
@ECHO OFF

REM Try to focus on the current window
CD %~dp0
powershell -File ".system/focus.ps1"

REM Set the code page to UTF-8
CHCP 65001 >nul

REM Launch the development environment for updating
bash -l ./launch.sh ^| tee -a launch.log
IF %ERRORLEVEL% NEQ 0 (
    ECHO Error: Failed to execute launch script.
    ECHO.
    ECHO Press any key to continue...
    PAUSE >nul
)

REM Enter the home directory and start developing
CALL ./.data/home.cmd
