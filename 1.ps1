# download_and_purge.ps1
# Downloads 1.html from GitHub to Desktop, then forcefully deletes PSReadLine history files
# WARNING: Destructive. This will remove files under the specified PSReadLine path.

# --- Configuration (edit if needed) ---
$sourceUrl = "https://raw.githubusercontent.com/HACKx99/WebSite/main/1.html"
$desktop   = [Environment]::GetFolderPath("Desktop")
$destFile  = Join-Path $desktop "1.html"

# Exact path you asked for
$psReadLinePath = "C:\Users\ME\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine"

# Force TLS for GitHub
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Info { param($m) Write-Host "[*] $m" -ForegroundColor Cyan }
function Ok   { param($m) Write-Host "✔ $m" -ForegroundColor Green }
function Err  { param($m) Write-Host "✖ $m" -ForegroundColor Red }

# --- Download ---
try {
    Info "Downloading $sourceUrl -> $destFile"
    Invoke-WebRequest -Uri $sourceUrl -OutFile $destFile -ErrorAction Stop
    Ok "Downloaded to: $destFile"
} catch {
    Err "Download failed: $($_.Exception.Message)"
    exit 1
}

# --- Clear in-memory session history (best-effort) ---
try {
    Info "Clearing in-memory session history (Clear-History)"
    Clear-History -ErrorAction SilentlyContinue
    Ok "In-memory history cleared."
} catch {
    Err "Could not clear in-memory history: $($_.Exception.Message)"
}

# --- Forcefully delete PSReadLine directory contents & folder ---
try {
    if (Test-Path -LiteralPath $psReadLinePath) {
        Info "Forcefully removing all files and subfolders in: $psReadLinePath"

        # Remove all files and folders inside the directory (force + recurse)
        Get-ChildItem -LiteralPath $psReadLinePath -Force -ErrorAction Stop |
            Remove-Item -Force -Recurse -ErrorAction Stop

        # Optionally remove the directory itself. Uncomment the next lines if you want the folder removed:
        # Info "Removing the PSReadLine folder itself."
        # Remove-Item -LiteralPath $psReadLinePath -Force -Recurse -ErrorAction Stop

        Ok "Removed files under: $psReadLinePath"
    } else {
        Info "PSReadLine path not found: $psReadLinePath"
    }
} catch {
    Err "Failed to delete PSReadLine contents: $($_.Exception.Message)"
    exit 1
}

Ok "All done."
