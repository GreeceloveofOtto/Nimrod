@echo off
setlocal
call "%~dp0tools\find_godot.bat"
if errorlevel 1 goto :failed
pushd "%~dp0"
echo [NIMROD] Launching the Godot project...
"%GODOT_BIN%" --path "%CD%" --editor --import
if errorlevel 1 (popd & goto :failed)
"%GODOT_BIN%" --path "%CD%"
set "rc=%ERRORLEVEL%"
popd
if not "%rc%"=="0" echo [WARNING] Godot exited with code %rc%.
pause
exit /b %rc%
:failed
echo See README_KO.txt for manual instructions.
pause
exit /b 1
