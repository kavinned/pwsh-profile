@echo off

:: Copy VS Code settings
copy "C:\Users\Kavin\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" "."

echo Profile copied successfully!

echo.

git add .
git commit -m 'sync'
git push

echo.

echo Pushed to GitHub successfully!

pause