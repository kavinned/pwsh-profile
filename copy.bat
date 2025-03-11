@echo off

:: Define source and fallback paths using environment variables
set "PROFILE_SOURCE=%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
set "PROFILE_FALLBACK=%OneDrive%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

set "SCRIPTS_SOURCE=%USERPROFILE%\Documents\PowerShell\Scripts"
set "SCRIPTS_FALLBACK=%OneDrive%\Documents\PowerShell\Scripts"

:: Check and copy PowerShell profile
echo Copying Profile...
if exist "%PROFILE_SOURCE%" (
	echo SOURCE PROFILE EXISTS
    copy "%PROFILE_SOURCE%" "."
) else if exist "%PROFILE_FALLBACK%" (
	echo USING FALLBACK
    copy "%PROFILE_FALLBACK%" "."
)

:: Check if Scripts folder exists and is not empty, then copy
echo Copying Scripts...
if exist "%SCRIPTS_SOURCE%" (
    dir /b "%SCRIPTS_SOURCE%" | findstr . >nul && (
		echo SOURCE SCRIPTS EXISTS
        xcopy "%SCRIPTS_SOURCE%" "./Scripts" /E /I /H /Y
    ) || (
        goto CHECK_FALLBACK
    )
) else (
	echo USING FALLBACK
    goto CHECK_FALLBACK
)

goto GIT_CHECK

:CHECK_FALLBACK
if exist "%SCRIPTS_FALLBACK%" (
    dir /b "%SCRIPTS_FALLBACK%" | findstr . >nul && (
        xcopy "%SCRIPTS_FALLBACK%" "./Scripts" /E /I /H /Y
    )
)

:GIT_CHECK
echo Profile copied successfully!

echo.

git diff

:: Ask user for GitHub push confirmation
set /p pushit=Do you want to push to GitHub? (y/n): 
if /i "%pushit%" neq "y" goto :eof

git add .
git commit -m 'sync'
git push

echo.

echo Pushed to GitHub successfully!

pause
