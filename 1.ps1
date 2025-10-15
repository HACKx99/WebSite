# ===========================
#  Simple GitHub Downloader
# ===========================

# --- GitHub raw file URL ---
$sourceUrl = "https://raw.githubusercontent.com/HACKx99/WebSite/main/1.html"

# --- Destination (Desktop) ---
$desktopPath = [Environment]::GetFolderPath("Desktop")
$destFile = Join-Path $desktopPath "1.html"

# --- Download File ---
try {
    Write-Host "Downloading from: $sourceUrl" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $sourceUrl -OutFile $destFile -UseBasicParsing -ErrorAction Stop
    Write-Host "File saved successfully to: $destFile" -ForegroundColor Green
}
catch {
    Write-Host "❌ Download failed: $($_.Exception.Message)" -ForegroundColor Red
}
