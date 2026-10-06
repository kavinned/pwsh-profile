#Requires -Version 7.0

function Clear-Cache {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Host "Clearing cache..." -ForegroundColor Cyan
    
    $totalFreed = 0
    
    # Helper to calculate directory size in MB
    function Get-DirectorySize {
        param([string]$Path)
        if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) { return 0 }
        try {
            $sum = (Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum).Sum
            return [math]::Round(($sum ?? 0) / 1MB, 2)
        }
        catch {
            return 0
        }
    }
    
    # Helper function to clear a directory-based cache
    function Clear-DirectoryCache {
        param(
            [string]$Name,
            [string]$Path,
            [scriptblock]$ClearCommand
        )
        
        Write-Host "Clearing $Name..." -ForegroundColor Yellow
        
        if ([string]::IsNullOrWhiteSpace($Path) -or $Path.StartsWith('\') -or -not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            Write-Host "  Directory not found" -ForegroundColor DarkGray
            return 0
        }
        
        $before = Get-DirectorySize $Path
        if ($before -le 0) {
            Write-Host "  Cache already empty" -ForegroundColor DarkGray
            return 0
        }

        if ($PSCmdlet.ShouldProcess($Path, "Clear cache")) {
            & $ClearCommand | Out-Null
            $after = Get-DirectorySize $Path
            $freed = [math]::Max(0, [math]::Round($before - $after, 2))
            Write-Host "  Cleared $freed MB" -ForegroundColor Green
            return $freed
        }
        return 0
    }
    
    # Helper function to clear command-based cache (pip, uv)
    function Clear-CommandCache {
        param(
            [string]$Name,
            [string]$CommandName,
            [scriptblock]$GetCacheDirCommand,
            [scriptblock]$ClearCommand
        )
        
        Write-Host "Clearing $Name..." -ForegroundColor Yellow
        
        if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
            Write-Host "  $CommandName not installed" -ForegroundColor DarkGray
            return 0
        }
        
        try {
            $cacheDir = & $GetCacheDirCommand 2>$null
            if ([string]::IsNullOrWhiteSpace($cacheDir) -or -not (Test-Path $cacheDir -ErrorAction SilentlyContinue)) {
                Write-Host "  Directory not found" -ForegroundColor DarkGray
                return 0
            }

            $before = Get-DirectorySize $cacheDir
            if ($before -le 0) {
                Write-Host "  Cache already empty" -ForegroundColor DarkGray
                return 0
            }

            if ($PSCmdlet.ShouldProcess($cacheDir, "Clean $CommandName cache")) {
                & $ClearCommand | Out-Null
                $after = Get-DirectorySize $cacheDir
                $freed = [math]::Max(0, [math]::Round($before - $after, 2))
                Write-Host "  Cleared $freed MB" -ForegroundColor Green
                return $freed
            }
            return 0
        } catch {
            Write-Host "  Directory not found" -ForegroundColor DarkGray
            return 0
        }
    }
    
    # Choco Cache
    if ($env:ChocolateyInstall) {
        $totalFreed += Clear-DirectoryCache -Name "Choco Cache" -Path "$env:ChocolateyInstall\cache" -ClearCommand { Remove-Item -Path "$env:ChocolateyInstall\cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    
    # Scoop Cache
    if (Test-Path "$env:USERPROFILE\scoop\cache" -ErrorAction SilentlyContinue) {
        $totalFreed += Clear-DirectoryCache -Name "Scoop Cache" -Path "$env:USERPROFILE\scoop\cache" -ClearCommand { scoop cache rm * }
    }
    
    # Stremio Cache
    if ($env:APPDATA) {
        $totalFreed += Clear-DirectoryCache -Name "Stremio Cache" -Path "$env:APPDATA\stremio\stremio-server\stremio-cache" -ClearCommand { Remove-Item -Path "$env:APPDATA\stremio\stremio-server\stremio-cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    
    # Kdenlive Cache
    if ($env:LOCALAPPDATA) {
        $totalFreed += Clear-DirectoryCache -Name "Kdenlive Cache" -Path "$env:LOCALAPPDATA\kdenlive\cache" -ClearCommand { Remove-Item -Path "$env:LOCALAPPDATA\kdenlive\cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    
    # UV Cache
    $totalFreed += Clear-CommandCache -Name "UV Cache" -CommandName "uv" -GetCacheDirCommand { uv cache dir } -ClearCommand { uv cache clean }
    
    # Pip Cache
    $totalFreed += Clear-CommandCache -Name "Pip Cache" -CommandName "pip" -GetCacheDirCommand { pip cache dir } -ClearCommand { pip cache purge }
    
    # Windows Prefetch
    if ($env:SystemRoot) {
        $totalFreed += Clear-DirectoryCache -Name "Windows Prefetch" -Path "$env:SystemRoot\Prefetch" -ClearCommand { Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue }
        $totalFreed += Clear-DirectoryCache -Name "Windows Temp" -Path "$env:SystemRoot\Temp" -ClearCommand { Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    
    # User Temp
    if ($env:TEMP) {
        $totalFreed += Clear-DirectoryCache -Name "User Temp" -Path $env:TEMP -ClearCommand { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    
    # IE Cache
    if ($env:LOCALAPPDATA) {
        $totalFreed += Clear-DirectoryCache -Name "Internet Explorer Cache" -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" -ClearCommand { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    
    Write-Host "`nCache clearing completed." -ForegroundColor Green
    Write-Host "Total space freed: $([math]::Round($totalFreed, 2)) MB ($([math]::Round($totalFreed / 1024, 2)) GB)" -ForegroundColor Magenta
}
