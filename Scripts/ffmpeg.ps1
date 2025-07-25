function 2Gif {
    param([string]$file)
    ffmpeg -i $file -vf "fps=15,scale=512:-1:flags=lanczos" -c:v gif "$([io.path]::GetFileNameWithoutExtension($file)).gif"
}
function CompressMp4 {
    param([string]$Exclude, [string]$Include)
    
    $compressedDir = "$PWD\compressed"
    if (!(Test-Path $compressedDir)) {
        New-Item -ItemType Directory -Path $compressedDir | Out-Null
    }
    
    Get-ChildItem *.mp4 | Where-Object {
        (!$Exclude -or $_.Name -notlike "*$Exclude*") -and 
        (!$Include -or $_.Name -like "*$Include*")
    } | ForEach-Object {
        Write-Host "Processing: $($_.Name)" -ForegroundColor Cyan
        $ErrorActionPreference = 'Continue'
        $outputFile = "$compressedDir\$($_.BaseName)_ffmpeg.mp4"
        $output = ffmpeg -i "$($_.FullName)" -c:v libx265 -b:v 6M -preset slow "$outputFile" -hide_banner -loglevel error 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error converting $($_.Name):" -ForegroundColor Red
            $output | Where-Object { $_ -ne $null } | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        }
    }
}
function GFF {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,
        [Alias("h")]
        [int]$Height = 1152
    )
    
    if (-not (Test-Path $InputFile)) {
        Write-Error "File '$InputFile' not found."
        return
    }
    
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    $OutputFile = "${BaseName}_first_frame.jpg"
    
    # Check if output already exists and prompt
    if (Test-Path $OutputFile) {
        $response = Read-Host "Output file '$OutputFile' already exists. Overwrite? (y/n)"
        if ($response -notmatch '^[yY]') {
            Write-Host "Skipped."
            return
        }
    }
    
    # Fixed: Use $Height for both width and height constraints
    ffmpeg -y -i $InputFile -vf "select=eq(n\,0),scale='min($Height,iw)':'min($Height,ih)':force_original_aspect_ratio=decrease" -frames:v 1 -q:v 2 $OutputFile -hide_banner -loglevel error
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "First frame saved as '$OutputFile'"
    }
}
function RevVid {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$InputFile,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile = "reversed.mp4"
    )
    
    # Check if input file exists
    if (-not (Test-Path $InputFile)) {
        Write-Error "Input file '$InputFile' does not exist."
        return
    }
    
    # Check if ffmpeg is available
    try {
        ffmpeg -version | Out-Null
    }
    catch {
        Write-Error "ffmpeg is not installed or not in PATH."
        return
    }
    
    # Build the ffmpeg command
    $ffmpegArgs = @(
        "-i", $InputFile,
        "-vf", "reverse",
        "-af", "areverse", 
        "-c:v", "h264_nvenc",
        "-cq", "19",
        $OutputFile
    )
    
    Write-Host "Reversing video: $InputFile -> $OutputFile"
    
    # Execute ffmpeg
    & ffmpeg @ffmpegArgs -hide_banner -loglevel error
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully created reversed video: $OutputFile" -ForegroundColor Green
    } else {
        Write-Error "ffmpeg failed with exit code $LASTEXITCODE"
    }
}
