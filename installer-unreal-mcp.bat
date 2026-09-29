@echo off
rem Lance setup-unreal-mcp.ps1 en demandant le dossier du projet Unreal.
set /p PROJET="Colle le chemin du dossier de ton projet Unreal (celui qui contient le .uproject) : "
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-unreal-mcp.ps1" -ProjectPath "%PROJET%"
pause
