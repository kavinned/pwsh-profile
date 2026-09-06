function webpconv {
    param (
        [Parameter(Mandatory=$true, Position=0)][string]$InputFile,
        [Parameter(Position=1)][string]$OutputFile,
        [Parameter(Position=2)][ValidateRange(0, 100)][int]$q = 80,
        [Parameter(Position=3)][int]$w = 0,
        [Parameter(Position=4)][int]$h = 0
    )

    if (!(Test-Path $InputFile)) {
        Write-Host "Error: Input file not found!" -ForegroundColor Red
        return
    }

    if (-not $OutputFile) {
        $FileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
        $OutputFile = "$FileName.webp"
    }

    $OutputDir = [System.IO.Path]::GetDirectoryName($OutputFile)
    if (-not $OutputDir -or $OutputDir -eq "") {
        $OutputDir = Get-Location
    }

    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }

    $OutputFile = [System.IO.Path]::Combine($OutputDir, [System.IO.Path]::GetFileName($OutputFile))

    # Check if output file exists and prompt
    if (Test-Path $OutputFile) {
        Write-Host "Output file '$OutputFile' already exists."
        $choice = Read-Host "Do you want to overwrite it? (Y/N)"
        if ($choice.ToUpper() -eq 'Y') {
            try {
                Remove-Item -Path $OutputFile -Force
                Write-Host "Existing file deleted." -ForegroundColor Yellow
            }
            catch {
                Write-Host "Error: Unable to delete existing file." -ForegroundColor Red
                return
            }
        } else {
            Write-Host "Conversion cancelled by user." -ForegroundColor Yellow
            return
        }
    }

    # Build scale filter
    $scale = if ($w -eq 0 -and $h -eq 0) {
        "scale=iw:-1:flags=lanczos"
    } else {
        "scale=$($w -eq 0 ? -1 : $w):$($h -eq 0 ? -1 : $h):flags=lanczos"
    }

    # Capture job start time
    $jobStartTime = Get-Date

    # Start ffmpeg in a background job
    $ffmpegJob = Start-Job -ScriptBlock {
        param ($InputFile, $OutputFile, $q, $scale)
        ffmpeg -loglevel error -i "$InputFile" -vf "$scale" -vcodec libwebp -lossless 0 -compression_level 5 -q:v $q -loop 0 -an -fps_mode passthrough "$OutputFile" >$null 2>&1
    } -ArgumentList $InputFile, $OutputFile, $q, $scale

    # Loading spinner
    $spinner = @("|", "/", "-", "\")
    $i = 0
    Write-Host "Converting... " -NoNewline
    while ($ffmpegJob.State -eq "Running") {
        Write-Host "`b$($spinner[$i])" -NoNewline
        Start-Sleep -Milliseconds 200
        $i = ($i + 1) % $spinner.Length
    }

    # Retrieve job result and clean up
    Receive-Job $ffmpegJob | Out-Null
    Remove-Job $ffmpegJob

    # Check if output was really modified
    $conversionSuccessful = $false
    if (Test-Path $OutputFile) {
        $fileInfo = Get-Item $OutputFile
        if ($fileInfo.LastWriteTime -gt $jobStartTime) {
            $conversionSuccessful = $true
        }
    }

    # Output success or failure message
    if ($conversionSuccessful) { 
        Write-Host "`bConversion successful: $OutputFile" -ForegroundColor Green 
    } else { 
        Write-Host "`bError: Conversion failed!" -ForegroundColor Red 
    }
}
