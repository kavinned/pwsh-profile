#Requires -Version 7.0

$profileTimer = [System.Diagnostics.Stopwatch]::StartNew()

# Starship Init (Cached execution)
$starshipCache = "$HOME\.starship-init-cache.ps1"
$starshipCmd   = Get-Command starship -ErrorAction SilentlyContinue

if ($starshipCmd -and (
        -not (Test-Path $starshipCache) -or
        ($starshipCmd.Source -and (Get-Item $starshipCmd.Source).LastWriteTime -gt (Get-Item $starshipCache -ErrorAction SilentlyContinue).LastWriteTime)
    )) {
    & starship init powershell --print-full-init | Out-File -FilePath $starshipCache -Encoding utf8
}

if (Test-Path $starshipCache) {
    try { . $starshipCache } catch {}
}

# Fast PSReadLine Setup
if (-not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected) {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -EditMode Windows
} else {
    Set-PSReadLineOption -PredictionSource None -EditMode Windows
}

# True Lazy Loading (Defers heavy module loading until shell is idle)
$null = Register-EngineEvent -SourceIdentifier 'PowerShell.OnIdle' -MaxTriggerCount 1 -Action {
    Import-Module -Name Terminal-Icons -Global -ErrorAction SilentlyContinue
    Import-Module -Name Microsoft.WinGet.CommandNotFound -Global -ErrorAction SilentlyContinue

    $scoopHook = & scoop-search --hook
    if ($scoopHook) {
        . ([scriptblock]::Create($scoopHook))
    }
}

# System Functions
function shutdown { param([Parameter(ValueFromRemainingArguments)]$Args) if ($Args) { shutdown.exe @Args } else { shutdown.exe /s /t 0 } }
function restart  { param([Parameter(ValueFromRemainingArguments)]$Args) if ($Args) { shutdown.exe @Args } else { shutdown.exe /r /t 0 } }
function abort    { shutdown.exe /a }

# Navigation Shortcuts
function idocs  { Set-Location "$HOME\Documents\_Important Documents" }
function coding { Set-Location "$HOME\Documents\_Important Documents\coding" }
function docs   { Set-Location "$HOME\Documents" }
function dtop   { Set-Location "$HOME\Desktop" }

# File Operations
function touch { param([string[]]$Files) foreach ($file in $Files) { if (-not (Test-Path $file)) { [System.IO.File]::Create($file).Dispose(); Write-Host "Created: $file" } } }
function open { param([string]$Dir = ".") Invoke-Item $Dir }
function nf { param([string]$name) New-Item -ItemType "file" -Path . -Name $name }
function mkcd { param([string]$dir) New-Item -ItemType Directory -Path $dir -Force | Out-Null && Set-Location $dir }
function unzip { param([string]$file, [string]$destination = ".") Expand-Archive -Path $file -DestinationPath $destination }
function resize {
    if (-not (Test-Path -Path "resized" -PathType Container)) {
        New-Item -ItemType Directory -Path "resized" | Out-Null
    }
    mogrify -path resized -resize "1024x1024>" *.jpg *.jpeg *.png *.webp *.tiff
}
function fix20 { Get-ChildItem -Filter "*%20*" -File -Recurse | Rename-Item -NewName { $_.Name -replace '%20', '' } }
function getHash { param([string]$Path) (Get-FileHash -Path $Path).Hash }
function pdf2md($file) {
    python -c "import pymupdf4llm, pathlib, sys; p = pathlib.Path(sys.argv[1]); p.with_suffix('.md').write_text(pymupdf4llm.to_markdown(str(p)), encoding='utf-8')" $file
}
function cleanmp4 {
    param(
        [Parameter(Position = 0)]
        [string]$File,
        [Alias('a')]
        [switch]$All,
        [Alias('o')]
        [switch]$Overwrite
    )
    $toolArgs = @('-all=', '-ext', 'mp4')
    if ($Overwrite) { $toolArgs += '-overwrite_original' }
    if ($All) {
        $toolArgs += '.'
    } elseif ($File) {
        $toolArgs += $File
    } else {
        Write-Error "Provide file or pass -a for current directory."
        return
    }
    exiftool @toolArgs
}

# System Operations
function df { Get-Volume }
function sysinfo { Get-ComputerInfo }
function flushdns { Clear-DnsClientCache; Write-Host "DNS cache flushed" }
function uptime { Get-Uptime }
function shizuku { param([Parameter(ValueFromRemainingArguments)]$AdbArgs) adb @AdbArgs shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh }
function ep { nano $PROFILE }
function nep { npp $PROFILE }
function ch { 
    npp "$($env:APPDATA)\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
}
function source { . $PROFILE }
function ipa { Invoke-RestMethod -Uri "https://api.ipify.org" }
function winutil {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
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
function pfind { param([int]$port) Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, State, OwningProcess }
function k9 { param([string]$process) Stop-Process -Name $process -Force }

function grep {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Regex,
        [Parameter(Position = 1)]
        [string]$Dir = ".",
        [Parameter(ValueFromPipeline = $true)]
        [psobject]$InputObject,
        [Alias('f', 'r')]
        [switch]$File
    )
    process {
        if (-not $File -and $null -ne $InputObject) {
            $text = if ($InputObject -is [System.IO.FileSystemInfo]) { $InputObject.Name } else { "$InputObject" }
            if ($text -match $Regex) {
                $InputObject
            }
        }
    }
    end {
        if ($File) {
            if (Test-Path -Path $Dir -PathType Leaf -ErrorAction SilentlyContinue) {
                Select-String -Path $Dir -Pattern $Regex
            } else {
                Get-ChildItem -Path $Dir -File -Recurse -ErrorAction SilentlyContinue | Select-String -Pattern $Regex
            }
        }
    }
}
function which { param([string]$name) (Get-Command $name -ErrorAction SilentlyContinue).Source ?? (Get-Command $name -ErrorAction SilentlyContinue).Definition }
function export { param([string]$name, [string]$value) Set-Item -Path "env:$name" -Value $value -Force }
function head { param([string]$file, [int]$lines=10) Get-Content -Path $file -TotalCount $lines }
function tail { param([string]$file, [int]$lines=10) Get-Content -Path $file -Tail $lines }
function hb { param([string]$text) Invoke-RestMethod -Uri "https://hastebin.com/documents" -Method Post -Body $text | Select-Object -ExpandProperty key }
function wc { @($input).Count }

# Git Shortcuts
function gs { git status }
function ga { git add . }
function gpull { git pull }
function gpush { git push }
function gcl { param([string]$repo) git clone "$repo" }
function gcom { param([string]$msg) git add . && git commit -m "$msg" }
function lazyg { param([string]$msg) git add . && git commit -m "$msg" && git push }
function gsmudge { $env:GIT_LFS_SKIP_SMUDGE = "1" }

# Clipboard
function cpy { param([string]$text) Set-Clipboard $text }
function pst { Get-Clipboard }

# Aliases
Set-Alias npp "C:\Program Files\Notepad++\notepad++.exe"
Set-Alias whr where.exe
Set-Alias pm pnpm
Set-Alias yn yarn
Set-Alias cc Clear-Cache
function ll { Get-ChildItem -Force }
function lh {
    Get-ChildItem -Force | Select-Object Name,
    @{
        Name = "Size"
        Expression = {
            if (-not $_.PSIsContainer) {
                $size = [double]$_.Length
                switch ($size) {
                    {$_ -ge 1GB} { "{0:N2} GB" -f ($size / 1GB); break }
                    {$_ -ge 1MB} { "{0:N2} MB" -f ($size / 1MB); break }
                    {$_ -ge 1KB} { "{0:N2} KB" -f ($size / 1KB); break }
                    default      { "$($_.Length) B" }
                }
            } else {
                ""  # Leave blank for directories
            }
        }
    },
    LastWriteTime | Format-Table -AutoSize
}

# Help Function
function Show-Help {
    @'
PowerShell Profile Help
=======================

Functions:
------------
Clear-Cache (cc) - Clears Windows and User cache directories.
shutdown [args] - Shuts down computer (defaults to -s -t 0).
restart [args] - Restarts computer (defaults to -r -t 0).
abort - Aborts active shutdown.
idocs - Navigate to _Important Documents directory.
coding - Navigate to coding directory under _Important Documents.
docs - Navigate to Documents directory.
dtop - Navigate to Desktop directory.
touch <file(s)> - Creates new file(s) if not existing.
resize - Creates 'resized' directory and resizes images to 1024px.
fix20 - Replaces '%20' in filenames with empty string.
getHash - Returns hash of input file.
pdf2md - Converts PDF file to Markdown.
cleanmp4 [file] [-a] [-o] - Strips metadata from mp4 via exiftool (-a all in dir, -o overwrite).
open <dir> - Opens directory via default handler.
nf <name> - Creates new file with given name.
mkcd <dir> - Creates directory and enters it.
unzip <file> [dest] - Extracts contents of zip file.
df - Displays disk volumes.
sysinfo - Displays system information.
flushdns - Clears DNS client cache.
uptime - Displays system uptime.
shizuku [args] - Executes Shizuku command with ADB.
ep - Opens profile in Nano.
nep - Opens profile in Notepad++.
ch - Opens console history in Notepad++.
source - Reloads profile.
ipa - Displays public IP address.
winutil - Runs Chris Titus Tech winutil script.

Process Management:
--------------------
admin <cmd> - Runs command in elevated terminal.
pkill <name> - Kills process by name.
pgrep <name> - Searches processes by name.
pfind <port> - Finds processes listening on port.
k9 <name> - Kills process by name.

Text Processing:
----------------
grep <regex> [dir] [-File|-f|-r] - Filters pipeline. Only searches files when -File flag passed.
sed <file> <find> <replace> - Regex replaces text in file.
which <cmd> - Displays command path or definition.
export <name> <value> - Sets environment variable.
head <file> [lines] - First lines of file.
tail <file> [lines] - Last lines of file.
hb <text> - Uploads text to Hastebin.
wc - Counts piped lines.

Git Shortcuts:
----------------
gs - git status
ga - git add .
gpull - git pull
gpush - git push
gcl <repo> - git clone
gcom <msg> - git add . && git commit -m <msg>
lazyg <msg> - git add . && git commit -m <msg> && git push
gsmudge - Sets GIT_LFS_SKIP_SMUDGE=1

Clipboard:
-----------
cpy <text> - Copies text to clipboard.
pst - Pastes text from clipboard.

Aliases:
---------
npp - Notepad++
whr - where.exe
pm - pnpm
yn - yarn
cc - Clear-Cache
ll - List files including hidden
lh - Long listing of files
'@ -split "`r?`n"
}

# Auto-import all .ps1 files from Scripts directory
$profileDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PROFILE) { Split-Path -Parent $PROFILE } else { "$HOME\Documents\PowerShell" }
$scriptsDir = Join-Path -Path $profileDir -ChildPath 'Scripts'
if (Test-Path -Path $scriptsDir) {
    Get-ChildItem -Path $scriptsDir -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }
}

if ($profileTimer) {
    $profileTimer.Stop()
    if (-not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected) {
        Write-Host "Use 'Show-Help' for help. Profile loaded in $($profileTimer.ElapsedMilliseconds)ms." -ForegroundColor DarkGray
    }
    Remove-Variable profileTimer -ErrorAction SilentlyContinue
}