function clear-cache {
    Write-Host "Clearing cache..." -ForegroundColor Cyan
    
    $totalFreed = 0
    
    # Function to calculate directory size
    function Get-DirectorySize {
        param([string]$Path)
        if (Test-Path $Path) {
            try {
                $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                return [math]::Round($size / 1MB, 2)
            }
            catch {
                return 0
            }
        }
        return 0
    }
    
    # Choco Cache
    Write-Host "Clearing Choco Cache..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:ChocolateyInstall\cache"
    sudo choco cache remove --all
    
    # Scoop Cache
    Write-Host "Clearing Scoop Cache..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:USERPROFILE\scoop\cache"
    scoop cache rm *
    
    # Stremio Cache
    Write-Host "Clearing Stremio Cache..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:APPDATA\stremio\stremio-server\stremio-cache"
    Remove-Item -Path "$env:APPDATA\stremio\stremio-server\stremio-cache" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Kdenlive Cache
    Write-Host "Clearing Kdenlive Cache..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:LOCALAPPDATA\kdenlive\cache"
    Remove-Item -Path "$env:LOCALAPPDATA\kdenlive\cache" -Recurse -ErrorAction SilentlyContinue
    
    # UV Cache
    Write-Host "Clearing UV Cache..." -ForegroundColor Yellow
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        try {
            $uvCacheOutput = uv cache dir 2>$null
            if ($uvCacheOutput) {
                $totalFreed += Get-DirectorySize $uvCacheOutput
            }
        } catch {}
    }
    uv cache clean
    
    # Pip Cache
    Write-Host "Clearing Pip Cache..." -ForegroundColor Yellow
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        try {
            $pipCacheDir = pip cache dir 2>$null
            if ($pipCacheDir) {
                $totalFreed += Get-DirectorySize $pipCacheDir
            }
        } catch {}
    }
    pip cache purge
    
    # Windows Prefetch
    Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:SystemRoot\Prefetch"
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
    
    # Windows Temp
    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:SystemRoot\Temp"
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # User Temp
    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:TEMP"
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # IE Cache
    Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
    $totalFreed += Get-DirectorySize "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "`nCache clearing completed." -ForegroundColor Green
    Write-Host "Total space freed: $([math]::Round($totalFreed, 2)) MB ($([math]::Round($totalFreed / 1024, 2)) GB)" -ForegroundColor Magenta
}