## My Profile
oh-my-posh init pwsh --config 'C:\Users\User\AppData\Local\Programs\oh-my-posh\themes\nordtron.omp.json' | Invoke-Expression
# Add auto complete (requires PSReadline 2.2.0-beta1+ prerelease)
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Import-Module -Name Terminal-Icons
Invoke-Expression (&scoop-search --hook)

function shutdown {
    Start-Process "shutdown.exe" -ArgumentList "-s -t 00"
}

function restart {
    Start-Process "shutdown.exe" -ArgumentList "-r -t 00"
}

function slp {
	Start-Process "C:\Users\User\Desktop\sleep.lnk"
	exit
}

function abort {
    Start-Process "shutdown.exe" -ArgumentList "-a"
}

Set-Alias npp "C:\Program Files\Notepad++\notepad++.exe" 

function shizuku($args) {
    adb $args shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh
}

function idocs { Set-Location -Path "$HOME\Documents\_Important Documents" }

function cdocs { Set-Location -Path "$HOME\Documents\_Important Documents\coding" }

function touch {
    param(
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [string[]]$Files
    )

    foreach ($file in $Files) {
        if (!(Test-Path $file)) {
            "" | Out-File -FilePath $file -Encoding ASCII
            Write-Host "Created file: $file"
        } else {
            Write-Host "File already exists: $file"
        }
    }
}

function open {
#open the directory in file explorer
    param(
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [string[]]$Dir
    )
    explorer.exe $Dir
}

function ep { nano $PROFILE } # Requires Nano for windows

function nep { npp $PROFILE} # Requires Notepad++

function source { & $PROFILE }

function df { get-volume }

function admin {
    if ($args.Count -gt 0) {
        $cmd = $args -join ' '
        $fullCommand = "Write-Host 'Executing: $args'; $cmd; Write-Host 'Done'"
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($fullCommand))
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -EncodedCommand $encodedCommand"
    } else {
        Start-Process wt -Verb runAs
    }
}

Set-Alias -Name sudo -Value admin

Set-Alias -Name whr -Value where.exe

## ChrisTitus Aliases
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Open WinUtil
function winutil {
	iwr -useb https://christitus.com/win | iex
}

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function hb {
    if ($args.Length -eq 0) {
        Write-Error "No file path specified."
        return
    }
    
    $FilePath = $args[0]
    
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }
    
    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Write-Output $url
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($identifier) {
    if ($identifier -match '^\d+$') {
        Get-Process -Id $identifier -ErrorAction SilentlyContinue | Stop-Process
    } else {
        Get-Process $identifier -ErrorAction SilentlyContinue | Stop-Process
    }
}

function pgrep($name) {
    Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

### Quality of Life Aliases

# Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }

function dtop { Set-Location -Path $HOME\Desktop }

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }

function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

function lh { ls -h }

# Git Shortcuts
function gs { git status }

function ga { git add . }

function gc { param($m) git commit -m "$m" }

function gp { git push }

function g { __zoxide_z github }

function gcl { git clone "$args" }

function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

function Show-Help {
    @"
PowerShell Profile Help
=======================

shutdown - Shuts down the computer.

restart - Restarts the computer.

slp - Sleeps the computer.

abort - Aborts the shutdown.

npp <file> - Opens the specified file in Notepad++.

admin/sudo <command> - Runs the current command as an administrator.

shizuku - Start the shizuku service while connected to an Android device.

whr <file> - Find the path of the specified file.

ep - Opens the current user's profile for editing using the configured editor.

source - Reloads the current user's PowerShell profile.

touch <file> - Creates a new empty file.

ff <name> - Finds files recursively with the specified name.

Get-PubIP - Retrieves the public IP address of the machine.

winutil - Runs the WinUtil script from Chris Titus Tech.

uptime - Displays the system uptime.

unzip <file> - Extracts a zip file to the current directory.

hb <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.

grep <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.

df - Displays information about volumes.

sed <file> <find> <replace> - Replaces text in a file.

which <name> - Shows the path of the command.

export <name> <value> - Sets an environment variable.

pkill <name> - Kills processes by name or ID.

pgrep <name> - Lists processes by name.

head <path> [n] - Displays the first n lines of a file (default 10).

tail <path> [n] - Displays the last n lines of a file (default 10).

nf <name> - Creates a new file with the specified name.

mkcd <dir> - Creates and changes to a new directory.

docs - Changes the current directory to the user's Documents folder.

dtop - Changes the current directory to the user's Desktop folder.

ep - Opens the profile for editing.

k9 <name> - Kills a process by name.

la - Lists all files in the current directory with detailed formatting.

ll - Lists all files, including hidden, in the current directory with detailed formatting.

lh - Lists hidden files in the current directory with detailed formatting.

gs - Shortcut for 'git status'.

ga - Shortcut for 'git add .'.

gc <message> - Shortcut for 'git commit -m'.

gp - Shortcut for 'git push'.

g - Changes to the GitHub directory.

gcom <message> - Adds all changes and commits with the specified message.

lazyg <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.

sysinfo - Displays detailed system information.

flushdns - Clears the DNS cache.

cpy <text> - Copies the specified text to the clipboard.

pst - Retrieves text from the clipboard.

Use 'Show-Help' to display this help message.
"@
}
Write-Host "Use 'Show-Help' to display help"
