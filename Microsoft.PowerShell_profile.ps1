# Load Oh-My-Posh Theme
oh-my-posh init pwsh --config "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\nordtron.omp.json" | Invoke-Expression

# Improve PSReadline Autocomplete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -EditMode Windows

# Lazy Load Modules
Import-Module -Name Terminal-Icons
if (!(Get-Module -ListAvailable -Name Microsoft.WinGet.CommandNotFound)) {
    Import-Module -Name Microsoft.WinGet.CommandNotFound
}
Invoke-Expression (&scoop-search --hook)

# Functions
function Clear-Cache {
    Write-Host "Clearing cache..." -ForegroundColor Cyan

    Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Cache clearing completed." -ForegroundColor Green
}

function shutdown { Start-Process "shutdown.exe" -ArgumentList "-s -t 00" }
function restart { Start-Process "shutdown.exe" -ArgumentList "-r -t 00" }
function abort { Start-Process "shutdown.exe" -ArgumentList "-a" }
function slp { Start-Process "C:\Users\User\Desktop\sleep.lnk"; exit }

# Navigation Shortcuts
function idocs { Set-Location "$HOME\Documents\_Important Documents" }
function cdocs { Set-Location "$HOME\Documents\_Important Documents\coding" }
function docs { Set-Location "$HOME\Documents" }
function dtop { Set-Location "$HOME\Desktop" }

# File Operations
function touch { param([string[]]$Files) foreach ($file in $Files) { if (!(Test-Path $file)) { "" | Out-File -FilePath $file; Write-Host "Created: $file" } } }
function open { param([string]$Dir) explorer.exe $Dir }
function nf { param([string]$name) New-Item -ItemType "file" -Path . -Name $name }
function mkcd { param([string]$dir) mkdir $dir -Force; Set-Location $dir }
function unzip { param([string]$file) Expand-Archive -Path $file }

# System Operations
function df { Get-Volume }
function sysinfo { Get-ComputerInfo }
function flushdns { Clear-DnsClientCache; Write-Host "DNS cache flushed" }
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}}
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}
function shizuku($args) { 
adb $args shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh
}
function ep { nano $PROFILE }
function nep { npp $PROFILE }
function source { . $PROFILE }
function Get-PubIP { Invoke-RestMethod -Uri "http://api.ipify.org" }
function winutil {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { iwr -useb https://christitus.com/win | iex }`"" -Verb RunAs
        return
    }
    iwr -useb https://christitus.com/win | iex
}

# Process Management
function admin { param([string]$cmd = "") 
	$argList = "pwsh.exe -NoExit"
    if ($cmd -ne "") {
        $argList += " -Command $cmd"
    }
    Start-Process wt -Verb runAs -ArgumentList $argList
}
function pkill { param([string]$identifier) Stop-Process -Name $identifier -Force }
function pgrep { param([string]$name) Get-Process -Name $name }
function pfind { param([int]$port) netstat -ano | Select-String ":$port\\s" }
function k9 { param([string]$process) Stop-Process -Name $process -Force }

# Text Processing
function grep { param([string]$regex, [string]$dir) if ($dir) { Get-ChildItem $dir | Select-String $regex } else { $input | Select-String $regex } }
function sed { param([string]$file, [string]$find, [string]$replace) (Get-Content $file).replace($find, $replace) | Set-Content $file }
function which { param([string]$name) Get-Command $name | Select-Object -ExpandProperty Definition }
function export { param([string]$name, [string]$value) Set-Item -Path "env:$name" -Value $value -Force }
function head { param([string]$file, [int]$lines=10) Get-Content $file | Select-Object -First $lines }
function tail { param([string]$file, [int]$lines=10) Get-Content $file | Select-Object -Last $lines }
function hb { param([string]$text) Invoke-RestMethod -Uri "https://hastebin.com/documents" -Method Post -Body $text | Select-Object -ExpandProperty key }

# Git Shortcuts
function gs { git status }
function ga { git add . }
function gc { param([string]$m) git commit -m "$m" }
function gp { git push }
function gcl { param([string]$repo) git clone "$repo" }
function gcom { param([string]$msg) git add .; git commit -m "$msg" }
function lazyg { param([string]$msg) git add .; git commit -m "$msg"; git push }

# Clipboard
function cpy { param([string]$text) Set-Clipboard $text }
function pst { Get-Clipboard }

# Aliases
Set-Alias npp "C:\Program Files\Notepad++\notepad++.exe"
Set-Alias whr where.exe
Set-Alias pm pnpm
Set-Alias yn yarn
Set-Alias la "ls"
Set-Alias ll "ls -Force"
Set-Alias lh "ls -lh"

# Help Function
function Show-Help {
    Write-Host "PowerShell Profile Help"
    Write-Host "======================="
    
    Write-Host "`nFunctions:"
    Write-Host "------------"
    Write-Host "Clear-Cache - Clears Windows and User cache directories."
    Write-Host "shutdown - Shuts down the computer."
    Write-Host "restart - Restarts the computer."
    Write-Host "abort - Aborts any active shutdown."
    Write-Host "slp - Activates the sleep shortcut on the desktop."
    Write-Host "idocs - Navigate to _Important Documents directory."
    Write-Host "cdocs - Navigate to coding directory under _Important Documents."
    Write-Host "docs - Navigate to Documents directory."
    Write-Host "dtop - Navigate to Desktop directory."
    Write-Host "touch <file(s)> - Creates a new file if it doesn't exist."
    Write-Host "open <directory> - Opens a directory in File Explorer."
    Write-Host "nf <name> - Creates a new file with the given name."
    Write-Host "mkcd <directory> - Creates a directory and moves into it."
    Write-Host "unzip <file> - Extracts contents from a zip file."
    Write-Host "df - Displays information about disk volumes."
    Write-Host "sysinfo - Displays system information."
    Write-Host "flushdns - Clears the DNS client cache."
    Write-Host "uptime - Displays the system uptime."
    Write-Host "shizuku <args> - Executes the Shizuku command with ADB."
    Write-Host "ep - Opens the profile file using Nano."
    Write-Host "nep - Opens the profile file using Notepad++."
    Write-Host "source - Reloads the profile script."
    Write-Host "Get-PubIP - Displays the public IP address."
    Write-Host "winutil - Executes a script from Chris Titus Tech."

    Write-Host "`nProcess Management:"
    Write-Host "--------------------"
    Write-Host "admin <cmd> - Runs a command as an administrator."
    Write-Host "pkill <identifier> - Kills a process by name."
    Write-Host "pgrep <name> - Searches for processes by name."
    Write-Host "pfind <port> - Finds processes listening on a given port."
    Write-Host "k9 <process> - Kills a process by name."

    Write-Host "`nText Processing:"
    Write-Host "----------------"
    Write-Host "grep <regex> <directory> - Searches files matching a regex in a directory."
    Write-Host "sed <file> <find> <replace> - Replaces text in a file."
    Write-Host "which <command> - Displays the full path of a command."
    Write-Host "export <name> <value> - Sets an environment variable."
    Write-Host "head <file> <lines> - Displays the first <lines> lines of a file."
    Write-Host "tail <file> <lines> - Displays the last <lines> lines of a file."
    Write-Host "hb <text> - Uploads text to Hastebin and returns the URL."

    Write-Host "`nGit Shortcuts:"
    Write-Host "----------------"
    Write-Host "gs - Displays the status of the git repository."
    Write-Host "ga - Stages all changes for commit."
    Write-Host "gc <message> - Commits staged changes with a message."
    Write-Host "gp - Pushes changes to the remote repository."
    Write-Host "gcl <repository> - Clones a git repository."
    Write-Host "gcom <message> - Stages, commits, and pushes changes."
    Write-Host "lazyg <message> - Stages, commits, and pushes changes with a single message."

    Write-Host "`nClipboard:"
    Write-Host "-----------"
    Write-Host "cpy <text> - Copies text to the clipboard."
    Write-Host "pst - Pastes text from the clipboard."

    Write-Host "`nAliases:"
    Write-Host "---------"
    Write-Host "npp - Opens Notepad++."
    Write-Host "whr - Finds the path of a command."
    Write-Host "pm - Alias for pnpm."
    Write-Host "yn - Alias for yarn."
    Write-Host "la - Alias for 'ls'."
    Write-Host "ll - Alias for 'ls -Force'."
    Write-Host "lh - Alias for 'ls -lh'."
}

Write-Host "Use 'Show-Help' to display help"
