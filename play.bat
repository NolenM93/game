@echo off
cd /d "%~dp0"
if exist "tools\godot\Godot_v4.7.2-stable_win64.exe" (
  echo Starting Lantern Hollow...
  start "" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
  exit /b 0
)
if exist "build\HarborPulse.exe" (
  echo Godot not found. Starting exported build...
  start "" "build\HarborPulse.exe"
  exit /b 0
)
echo Could not find Godot or an exported build.
pause
