<#
.SYNOPSIS
  Main script to download 1.html from GitHub to Desktop.

.DESCRIPTION
  Downloads 1.html and saves it to the user's Desktop.
#>

# --- Configuration ---
$rawHtmlUrl = 'https://raw.githubusercontent.com/HACKx99/WebSite/main/1.html'
$desktop    = [Environment]::GetFolderPath('Desktop')
$htmlName   = '1.html'
$htmlPath   = Join-Path $desktop $htmlName

# Force TLS 1.2 (GitHub requires modern TLS)
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Write-Info { param($m) Write-Host "[*] $m" -ForegroundColor Cyan }
function Write-Err  { param($m) Write-Host "[!] $m" -ForegroundColor Red }

# --- Download Function ---
function Download-File {
    param(
        [string] $Url,
        [string] $OutFile
    )

    try {
        Write-Info "Downloading from $Url"
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -ErrorAction Stop
        Write-Info "Saved: $OutFile"
        return $true
    } catch {
        Write-Err "Download failed: $($_.Exception.Message)"
        return $false
    }
}

# --- Main Logic ---
Write-Info "Preparing to download 1.html to Desktop..."
if (Test-Path $htmlPath) {
    $answer = Read-Host "File already exists on Desktop. Overwrite? (Y/N)"
    if ($answer -notmatch '^[Yy]') {
        Write-Info "Aborted by user."
        exit
    }
    Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
}

Download-File -Url $rawHtmlUrl -OutFile $htmlPath

Write-Info "Done. File saved to: $htmlPath"

# --- Clear PowerShell session/history ---
try {
    Write-Host "Clearing session history..." -ForegroundColor Cyan
    Clear-History

    $histFile = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if (Test-Path $histFile) {
        Remove-Item $histFile -Force
        Write-Host "Deleted PowerShell history file." -ForegroundColor Green
    } else {
        Write-Host "No history file found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to clear history: $($_.Exception.Message)" -ForegroundColor Red
}
