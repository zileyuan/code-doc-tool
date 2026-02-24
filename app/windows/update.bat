@echo off
setlocal enabledelayedexpansion

set "OLD_APP=%~1"
set "NEW_APP=%~2"

if "%OLD_APP%"=="" (
    echo Usage: %~nx0 ^<old_app_path^> ^<new_app_path^>
    exit /b 1
)

if "%NEW_APP%"=="" (
    echo Usage: %~nx0 ^<old_app_path^> ^<new_app_path^>
    exit /b 1
)

echo Waiting for application to quit...
timeout /t 2 /nobreak >nul

:WAIT_LOOP
tasklist /FI "IMAGENAME eq code_doc_tool.exe" 2>nul | find /I "code_doc_tool.exe" >nul
if %errorlevel%==0 (
    echo Application still running, waiting...
    timeout /t 1 /nobreak >nul
    goto WAIT_LOOP
)

echo Removing old application files...
if exist "%OLD_APP%" (
    rd /s /q "%OLD_APP%"
)

echo Installing new application files...
xcopy "%NEW_APP%\*" "%OLD_APP%\" /E /I /Y

echo Launching new application...
start "" "%OLD_APP%\code_doc_tool.exe"

echo Update completed!
