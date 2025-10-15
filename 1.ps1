<#
download.ps1
Simple GitHub downloader + optional PowerShell history cleanup

Usage:
  PowerShell -ExecutionPolicy Bypass -File "download.ps1"            # normal run (prompts to clear history)
  PowerShell -ExecutionPolicy Bypass -File "download.ps1" -Force    # skip confirmation (overwrites & deletes)
  PowerShell -ExecutionPolicy Bypass -File "download.ps1" -NoPrompt # download only, no prompts about clearing history
#>

param(
    [switch] $Force,      # skip confirmations (use with care)
    [switch] $NoPrompt    # do not prompt after download (will not clear history unless -Force)
)

# --- Configuration ---
$sourceUrl   = "https://raw.githubusercontent.com/HACKx99/WebSite/main/1.html"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$destFile    = Join-Path $desktopPath "1.html"

# PSReadLine history file path (platform-aware via %APPDATA%)
$psReadLineDir  = Join-Path $env:APPDATA "Microsoft\Windows\PowerShell\PSReadLine"
$psHistoryFile  = Join-Path $psReadLineDir "ConsoleHost_history.txt"

# --- Helper functions ---
function Write-Info { param($m) Write-Host "[*] $m" -ForegroundColor Cyan }
function Write-OK   { param($m) Write-Host "✔ $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "⚠ $m" -ForegroundColor Yellow }
function Write-Err  { param($m) Write-Host "✖ $m" -ForegroundColor Red }

# --- Download file ---
try {
    Write-Info "Downloading from: $sourceUrl"
    Invoke-WebRequest -Uri $sourceUrl -OutFile $destFile -ErrorAction Stop
    Write-OK "File saved to: $destFile"
} catch {
    Write-Err "Download failed: $($_.Exception.Message)"
    exit 1
}

# --- Decide whether to clear history ---
$shouldClear = $false
if ($Force) {
    $shouldClear = $true
} elseif ($NoPrompt) {
    $shouldClear = $false
} else {
    $ans = Read-Host "Do you want to clear PowerShell session history and delete PSReadLine history file? (Y/N)"
    if ($ans -match '^[Yy]') { $shouldClear = $true } else { $shouldClear = $false }
}

if ($shouldClear) {
    try {
        Write-Info "Clearing in-memory session history..."
        Clear-History -ErrorAction SilentlyContinue
        Write-OK "Session history cleared."

        if (Test-Path $psHistoryFile) {
            Write-Info "Deleting PSReadLine history file: $psHistoryFile"
            Remove-Item -LiteralPath $psHistoryFile -Force -ErrorAction Stop
            Write-OK "Deleted PSReadLine history file."
        } else {
            Write-Warn "No PSReadLine history file found at: $psHistoryFile"
        }
    } catch {
        Write-Err "Failed to clear/delete history: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Info "Skipping history cleanup."
}

Write-OK "Done."
