<# 
Codex Smooth Optimizer
Conservative Windows cleanup for low-RAM PCs before running Codex.

What it does:
- Shows RAM, pagefile, disk, and top process usage.
- Stops optional background apps for the current session.
- Optionally disables selected current-user startup entries.
- Does not stop Windows Defender, Windows Update, drivers, or core services.

Run:
  powershell -ExecutionPolicy Bypass -File .\CodexSmoothOptimizer.ps1

Optional:
  powershell -ExecutionPolicy Bypass -File .\CodexSmoothOptimizer.ps1 -SessionClean
  powershell -ExecutionPolicy Bypass -File .\CodexSmoothOptimizer.ps1 -DisableStartup
#>

[CmdletBinding()]
param(
    [switch]$SessionClean,
    [switch]$DisableStartup,
    [switch]$ReportOnly
)

$ErrorActionPreference = "Continue"

$optionalProcesses = @(
    "OneDrive",
    "GoogleDriveFS",
    "PhoneExperienceHost",
    "YourPhone",
    "msedge",
    "chrome",
    "opera",
    "GooglePlayGamesServices",
    "GooglePlayGames",
    "GoogleUpdater"
)

$startupNamePatterns = @(
    "GoogleChromeAutoLaunch*",
    "MicrosoftEdgeAutoLaunch*",
    "Byteconnect",
    "GoogleDriveFS",
    "OneDrive"
)

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host "== $Text ==" -ForegroundColor Cyan
}

function Read-YesNo {
    param(
        [string]$Prompt,
        [bool]$Default = $false
    )

    $suffix = if ($Default) { "[Y/n]" } else { "[y/N]" }
    $answer = Read-Host "$Prompt $suffix"

    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $Default
    }

    return $answer.Trim().ToLowerInvariant().StartsWith("y")
}

function Get-MemorySnapshot {
    $os = Get-CimInstance Win32_OperatingSystem
    [PSCustomObject]@{
        TotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        FreeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        FreePct = [math]::Round(($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 1)
    }
}

function Show-SystemReport {
    Write-Title "System Snapshot"

    $memory = Get-MemorySnapshot
    $memory | Format-List

    Write-Host "Pagefile:" -ForegroundColor Yellow
    Get-CimInstance Win32_PageFileUsage |
        Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage |
        Format-Table -AutoSize

    Write-Host "Drives:" -ForegroundColor Yellow
    Get-Volume |
        Where-Object DriveLetter |
        Select-Object DriveLetter, FileSystemLabel, HealthStatus,
            @{n = "SizeGB"; e = { [math]::Round($_.Size / 1GB, 1) } },
            @{n = "FreeGB"; e = { [math]::Round($_.SizeRemaining / 1GB, 1) } },
            @{n = "FreePct"; e = { [math]::Round(($_.SizeRemaining / $_.Size) * 100, 1) } } |
        Sort-Object DriveLetter |
        Format-Table -AutoSize

    Write-Host "Top RAM users:" -ForegroundColor Yellow
    Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 12 ProcessName, Id,
            @{n = "RAM_MB"; e = { [math]::Round($_.WorkingSet64 / 1MB, 1) } },
            CPU |
        Format-Table -AutoSize
}

function Stop-OptionalBackgroundApps {
    Write-Title "Session Cleanup"

    $targets = Get-Process |
        Where-Object { $optionalProcesses -contains $_.ProcessName } |
        Sort-Object ProcessName, Id

    if (-not $targets) {
        Write-Host "No optional background apps from the cleanup list are running."
        return
    }

    Write-Host "These optional apps can be stopped for this session:" -ForegroundColor Yellow
    $targets |
        Select-Object ProcessName, Id,
            @{n = "RAM_MB"; e = { [math]::Round($_.WorkingSet64 / 1MB, 1) } } |
        Format-Table -AutoSize

    if (-not (Read-YesNo "Stop these apps now? Codex and Windows security will be left alone." $true)) {
        Write-Host "Skipped session cleanup."
        return
    }

    foreach ($process in $targets) {
        try {
            Stop-Process -Id $process.Id -Force -ErrorAction Stop
            Write-Host "Stopped $($process.ProcessName) [$($process.Id)]"
        }
        catch {
            Write-Warning "Could not stop $($process.ProcessName) [$($process.Id)]: $($_.Exception.Message)"
        }
    }
}

function Disable-CurrentUserStartupEntry {
    param(
        [Microsoft.Win32.RegistryKey]$RunKey,
        [Microsoft.Win32.RegistryKey]$DisabledKey,
        [string]$Name,
        [string]$Command
    )

    $DisabledKey.SetValue($Name, $Command)
    $RunKey.DeleteValue($Name)
}

function Disable-SelectedStartupEntries {
    Write-Title "Startup Cleanup"

    $runPath = "Software\Microsoft\Windows\CurrentVersion\Run"
    $disabledPath = "Software\CodexSmoothOptimizer\DisabledStartup"
    $runKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($runPath, $true)

    if (-not $runKey) {
        Write-Host "No current-user startup Run key was found."
        return
    }

    $disabledKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($disabledPath)
    $matches = @()

    foreach ($name in $runKey.GetValueNames()) {
        foreach ($pattern in $startupNamePatterns) {
            if ($name -like $pattern) {
                $matches += [PSCustomObject]@{
                    Name = $name
                    Command = [string]$runKey.GetValue($name)
                }
                break
            }
        }
    }

    if (-not $matches) {
        Write-Host "No matching current-user startup entries found."
        return
    }

    Write-Host "These startup entries can be disabled. A backup is saved in HKCU:\$disabledPath" -ForegroundColor Yellow
    $matches | Format-Table -Wrap -AutoSize

    if (-not (Read-YesNo "Disable these startup entries?" $false)) {
        Write-Host "Skipped startup cleanup."
        return
    }

    foreach ($entry in $matches) {
        try {
            Disable-CurrentUserStartupEntry -RunKey $runKey -DisabledKey $disabledKey -Name $entry.Name -Command $entry.Command
            Write-Host "Disabled startup entry: $($entry.Name)"
        }
        catch {
            Write-Warning "Could not disable $($entry.Name): $($_.Exception.Message)"
        }
    }

    Write-Host "Restart Windows later to feel the full startup improvement."
}

function Show-Advice {
    Write-Title "Best Next Steps"
    Write-Host "1. Close browsers, cloud sync, Phone Link, and downloaders before long Codex sessions."
    Write-Host "2. Keep at least 8-10 GB free on C: for Windows pagefile and updates."
    Write-Host "3. The biggest hardware upgrade for this PC is a SATA SSD, then 8 GB+ RAM."
    Write-Host "4. Run Windows Security > Virus & threat protection > Full scan when you are not working."
}

Write-Host "Codex Smooth Optimizer" -ForegroundColor Green
Write-Host "This script is conservative. It avoids system services and security processes."

Show-SystemReport

if ($ReportOnly) {
    Show-Advice
    exit 0
}

if (-not $SessionClean -and -not $DisableStartup) {
    $SessionClean = Read-YesNo "Run session cleanup now?" $true
    $DisableStartup = Read-YesNo "Also offer startup cleanup? This changes current-user startup entries." $false
}

if ($SessionClean) {
    Stop-OptionalBackgroundApps
}

if ($DisableStartup) {
    Disable-SelectedStartupEntries
}

Show-SystemReport
Show-Advice
