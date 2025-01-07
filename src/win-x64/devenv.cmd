:: ======================================================================
:: Launches the development environment for the current project.
:: NOTE: All the necessary configurations are done in the `launch.sh` script.
:: ======================================================================
@ECHO OFF
CD %~dp0
CHCP 65001 >nul

bash -l ./launch.sh
IF %ERRORLEVEL% NEQ 0 (
    ECHO Error: Failed to execute launch script.
    ECHO.
    ECHO Press any key to continue...
    PAUSE >nul
)

call ./.data/home.cmd
