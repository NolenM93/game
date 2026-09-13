@echo off
cd /d "%~dp0"
if exist "build\HarborPulse.exe" (
  echo Starting Lantern Hollow...
  start "" "build\HarborPulse.exe"
  exit /b 0
)
echo Exported game not found. Launching with Godot...
start "" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
