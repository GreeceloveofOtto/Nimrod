@echo off
set "GODOT_BIN="
if defined GODOT_EXE (
  if exist "%GODOT_EXE%" set "GODOT_BIN=%GODOT_EXE%"
)
if defined GODOT_BIN goto :done
for %%C in (godot.exe godot4.exe Godot.exe) do (
  if not defined GODOT_BIN (
    for /f "delims=" %%G in ('where %%C 2^>nul') do (
      if not defined GODOT_BIN set "GODOT_BIN=%%G"
    )
  )
)
if defined GODOT_BIN goto :done
for %%G in ("%~dp0..\Godot*.exe" "%~dp0..\..\Godot*.exe") do (
  if not defined GODOT_BIN if exist "%%~fG" set "GODOT_BIN=%%~fG"
)
:done
if defined GODOT_BIN exit /b 0
echo [ERROR] Godot 4 editor was not found.
echo Download Godot 4.3 or later from https://godotengine.org/download/windows/
echo Or set GODOT_EXE to the Godot editor executable full path.
exit /b 1
