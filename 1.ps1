# Download-GitHubFileToDesktop.ps1
# Download file from GitHub and save to current user's Desktop.

# Force TLS1.2 for GitHub HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Input URL (the blob URL you provided)
$githubBlobUrl = 'https://github.com/HACKx99/WebSite/blob/main/1.html'

# Convert blob URL -> raw.githubusercontent.com URL
$rawUrl = $githubBlobUrl -replace '^https://github\.com/', 'https://raw.githubusercontent.com/' -replace '/blob/','/'

# Destination on Desktop
$desktop = [Environment]::GetFolderPath('Desktop')
$filename = '1.html'
$dest = Join-Path $desktop $filename

# If file exists ask before overwriting
if (Test-Path $dest) {
    $answer = Read-Host "File '$filename' already exists on your Desktop. Overwrite? (Y/N)"
    if ($answer -notmatch '^[Yy]') {
        Write-Host 'Aborting — file not overwritten.'; exit 0
    }
}

# Try downloading the raw file first (preferred)
try {
    Invoke-WebRequest -Uri $rawUrl -OutFile $dest -ErrorAction Stop
    Write-Host "Downloaded raw file to: $dest"
    exit 0
} catch {
    Write-Warning "Raw download failed: $($_.Exception.Message)"
    Write-Host "Trying blob page (may include GitHub UI wrapper)..."
}

# Fallback: download the blob web page (less desirable)
try {
    Invoke-WebRequest -Uri $githubBlobUrl -OutFile $dest -ErrorAction Stop
    Write-Host "Downloaded blob page to: $dest"
} catch {
    Write-Error "Download failed: $($_.Exception.Message)"
}
