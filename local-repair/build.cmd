@echo off
setlocal
for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "AGENT2API_VS=%%i"
if not defined AGENT2API_VS exit /b 1
call "%AGENT2API_VS%\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
cd /d "%~dp0source\desktop-tauri\src-tauri"
"%USERPROFILE%\.cargo\bin\cargo.exe" build --release --locked -p workbuddy-proxy-desktop
exit /b %errorlevel%
