function webpconv {
    param (
        [Parameter(Mandatory=$true, Position=0)][string]$InputFile,
        [Parameter(Position=1)][string]$OutputFile
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

    # Start ffmpeg in a background job
    $ffmpegJob = Start-Job -ScriptBlock {
        param ($InputFile, $OutputFile)
        ffmpeg -loglevel error -i "$InputFile" -vf "scale=iw:-1:flags=lanczos" -vcodec libwebp -lossless 0 -compression_level 5 -q:v 80 -loop 0 -an -fps_mode passthrough "$OutputFile" >$null 2>&1
    } -ArgumentList $InputFile, $OutputFile

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

    # Output success or failure message
    if (Test-Path $OutputFile) { 
        Write-Host "`bConversion successful: $OutputFile" -ForegroundColor Green 
    } else { 
        Write-Host "`bError: Conversion failed!" -ForegroundColor Red 
    }
}
