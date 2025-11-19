function clear-cache {
    Write-Host "Clearing cache..." -ForegroundColor Cyan
    
    $totalFreed = 0
    
    # Function to calculate directory size
    function Get-DirectorySize {
        param([string]$Path)
        if (Test-Path $Path) {
            try {
                $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
                         Measure-Object -Property Length -Sum).Sum
                if ($size -eq $null) { return 0 }
                return [math]::Round($size / 1MB, 2)
            }
            catch {
                return 0
            }
        }
        return -1
    }
    
    # Helper function to clear a directory-based cache
    function Clear-DirectoryCache {
        param(
            [string]$Name,
            [string]$Path,
            [scriptblock]$ClearCommand
        )
        
        Write-Host "Clearing $Name..." -ForegroundColor Yellow
        
        if (-not (Test-Path $Path)) {
            Write-Host "  Directory not found" -ForegroundColor DarkGray
            return 0
        }
        
        $size = Get-DirectorySize $Path
        if ($size -gt 0) {
            & $ClearCommand | Out-Null
            Write-Host "  Cleared $size MB" -ForegroundColor Green
            return $size
        } else {
            Write-Host "  Cache already empty" -ForegroundColor DarkGray
            return 0
        }
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
            if ($cacheDir -and (Test-Path $cacheDir)) {
                $size = Get-DirectorySize $cacheDir
                if ($size -gt 0) {
                    & $ClearCommand | Out-Null
                    Write-Host "  Cleared $size MB" -ForegroundColor Green
                    return $size
                } else {
                    Write-Host "  Cache already empty" -ForegroundColor DarkGray
                    return 0
                }
            } else {
                Write-Host "  Directory not found" -ForegroundColor DarkGray
                return 0
            }
        } catch {
            Write-Host "  Directory not found" -ForegroundColor DarkGray
            return 0
        }
    }
    
    # Choco Cache (package nupkg files)
    $totalFreed += Clear-DirectoryCache -Name "Choco Cache" -Path "$env:ChocolateyInstall\cache" -ClearCommand { Remove-Item -Path "$env:ChocolateyInstall\cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    # Scoop Cache
    $totalFreed += Clear-DirectoryCache -Name "Scoop Cache" -Path "$env:USERPROFILE\scoop\cache" -ClearCommand { scoop cache rm * }
    
    # Stremio Cache
    $totalFreed += Clear-DirectoryCache -Name "Stremio Cache" -Path "$env:APPDATA\stremio\stremio-server\stremio-cache" -ClearCommand { Remove-Item -Path "$env:APPDATA\stremio\stremio-server\stremio-cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    # Kdenlive Cache
    $totalFreed += Clear-DirectoryCache -Name "Kdenlive Cache" -Path "$env:LOCALAPPDATA\kdenlive\cache" -ClearCommand { Remove-Item -Path "$env:LOCALAPPDATA\kdenlive\cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    # UV Cache
    $totalFreed += Clear-CommandCache -Name "UV Cache" -CommandName "uv" -GetCacheDirCommand { uv cache dir } -ClearCommand { uv cache clean }
    
    # Pip Cache
    $totalFreed += Clear-CommandCache -Name "Pip Cache" -CommandName "pip" -GetCacheDirCommand { pip cache dir } -ClearCommand { pip cache purge }
    
    # Windows Prefetch
    $totalFreed += Clear-DirectoryCache -Name "Windows Prefetch" -Path "$env:SystemRoot\Prefetch" -ClearCommand { Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue }
    
    # Windows Temp
    $totalFreed += Clear-DirectoryCache -Name "Windows Temp" -Path "$env:SystemRoot\Temp" -ClearCommand { Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    # User Temp
    $totalFreed += Clear-DirectoryCache -Name "User Temp" -Path $env:TEMP -ClearCommand { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    # IE Cache
    $totalFreed += Clear-DirectoryCache -Name "Internet Explorer Cache" -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" -ClearCommand { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    Write-Host "`nCache clearing completed." -ForegroundColor Green
    Write-Host "Total space freed: $([math]::Round($totalFreed, 2)) MB ($([math]::Round($totalFreed / 1024, 2)) GB)" -ForegroundColor Magenta
}
