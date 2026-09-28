@echo off
cd /d "%~dp0"
"D:\5E\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
if errorlevel 1 (
  echo.
  echo MARS failed to start. Please copy the error message above.
  pause
)

