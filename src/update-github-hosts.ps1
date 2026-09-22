<#
.SYNOPSIS
    Updates the Windows hosts file with GitHub520 project entries.

.DESCRIPTION
    Fetches the latest hosts entries from the GitHub520 project and updates
    the managed section of the Windows hosts file. The script maintains a
    delimited section (# BEGIN GitHub520 / # END GitHub520) and only modifies
    entries within that section, preserving all other custom hosts entries.

    The script requires administrator privileges and will self-elevate if needed.

.PARAMETER WhatIf
    Dry-run mode. Shows what would happen without modifying any files.

.PARAMETER Verbose
    Detailed logging of each step.

.PARAMETER Force
    Skip change detection and always update, even if content hasn't changed.

.PARAMETER Rollback
    Restore the hosts file from the .bak backup file.

.EXAMPLE
    .\update-github-hosts.ps1
    Runs the update. If content has changed, updates the managed section.

.EXAMPLE
    .\update-github-hosts.ps1 -WhatIf
    Shows what would happen without modifying the hosts file.

.EXAMPLE
    .\update-github-hosts.ps1 -Verbose
    Runs with detailed logging.

.EXAMPLE
    .\update-github-hosts.ps1 -Force
    Skips change detection and updates even if content hasn't changed.

.EXAMPLE
    .\update-github-hosts.ps1 -Rollback
    Restores the hosts file from the backup.

.NOTES
    Requires PowerShell 5.1+ and administrator privileges.
    Remote source: https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    [switch]$Rollback
)

# --- Configuration ---
$SourceUrl = 'https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts'
$HostsPath = 'C:\Windows\System32\drivers\etc\hosts'
$BackupPath = 'C:\Windows\System32\drivers\etc\hosts.bak'
$BeginMarker = '# BEGIN GitHub520'
$EndMarker = '# END GitHub520'

# --- Helper Functions ---

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-SelfElevation {
    $argString = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Force) { $argString += " -Force" }
    if ($Rollback) { $argString += " -Rollback" }
    if ($VerbosePreference -eq 'Continue') { $argString += " -Verbose" }
    if ($WhatIfPreference) { $argString += " -WhatIf" }

    Write-Verbose "Self-elevating with arguments: $argString"
    Start-Process -FilePath $PSHOME\powershell.exe -ArgumentList $argString -Verb RunAs -Wait
    exit $LASTEXITCODE
}

function Get-RemoteContent {
    Write-Verbose "Fetching remote content from $SourceUrl..."
    try {
        $response = Invoke-WebRequest -Uri $SourceUrl -UseBasicParsing -ErrorAction Stop
        $content = $response.Content
        Write-Verbose "Fetched $($content.Length) bytes"
        return $content
    }
    catch {
        Write-Error "Failed to fetch remote content: $_"
        return $null
    }
}

function Test-ContentValid {
    param([string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) {
        Write-Warning "Validation failed: remote content is empty"
        return $false
    }

    if ($Content -match '<html' -or $Content -match '<!DOCTYPE') {
        Write-Warning "Validation failed: remote content appears to be an HTML error page"
        return $false
    }

    # Check for at least one valid hosts entry (IP + domain)
    $hostsPattern = '^\s*\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s+\S+'
    $lines = $Content -split "`n"
    $validEntries = @($lines | Where-Object { $_ -match $hostsPattern })

    if ($validEntries.Count -eq 0) {
        Write-Warning "Validation failed: no valid hosts entries found in remote content"
        return $false
    }

    Write-Verbose "Validation passed: found $($validEntries.Count) hosts entries"
    return $true
}

function Get-ManagedSection {
    param([string]$HostsContent)

    $lines = $HostsContent -split "`r?`n"
    $beginIndex = -1
    $endIndex = -1

    $escapedBegin = [regex]::Escape($BeginMarker)
    $escapedEnd = [regex]::Escape($EndMarker)

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^$escapedBegin") {
            $beginIndex = $i
        }
        if ($lines[$i] -match "^$escapedEnd") {
            $endIndex = $i
            break
        }
    }

    if ($beginIndex -eq -1 -or $endIndex -eq -1) {
        return $null
    }

    $sectionLines = $lines[$beginIndex..$endIndex]
    return @{
        BeginIndex = $beginIndex
        EndIndex = $endIndex
        Content = ($sectionLines -join "`n")
        FullContent = $HostsContent
    }
}

function Get-ContentHash {
    param([string]$Content)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($bytes)
    return [BitConverter]::ToString($hash) -replace '-', ''
}

function Get-ManagedSectionContent {
    param([string]$Section)

    # Extract content between markers (excluding the marker lines themselves)
    $lines = $Section -split "`r?`n"
    $contentLines = @()
    $inSection = $false

    $escapedBegin = [regex]::Escape($BeginMarker)
    $escapedEnd = [regex]::Escape($EndMarker)

    foreach ($line in $lines) {
        if ($line -match "^$escapedBegin") {
            $inSection = $true
            continue
        }
        if ($line -match "^$escapedEnd") {
            break
        }
        if ($inSection) {
            $contentLines += $line
        }
    }

    return ($contentLines -join "`n")
}

function New-ManagedSection {
    param(
        [string]$Content
    )

    $timestamp = (Get-Date).ToString('yyyy-MM-dd')
    $beginLine = "$BeginMarker ($timestamp)"
    $endLine = $EndMarker

    return "$beginLine`n$Content`n$endLine"
}

function Update-HostsFile {
    param(
        [string]$HostsContent,
        [string]$NewSection
    )

    $managedSection = Get-ManagedSection -HostsContent $HostsContent

    if ($null -eq $managedSection) {
        # First run: append section at end
        Write-Verbose "No managed section found. Appending new section at end of hosts file."
        $newContent = $HostsContent.TrimEnd() + "`n`n$NewSection`n"
        return $newContent
    }

    # Replace existing section
    $lines = $HostsContent -split "`r?`n"
    $beforeLines = @()
    $afterLines = @()

    for ($i = 0; $i -lt $managedSection.BeginIndex; $i++) {
        $beforeLines += $lines[$i]
    }

    for ($i = $managedSection.EndIndex + 1; $i -lt $lines.Count; $i++) {
        $afterLines += $lines[$i]
    }

    $result = ($beforeLines -join "`n") + "`n" + $NewSection + "`n" + ($afterLines -join "`n")
    return $result
}

function Backup-HostsFile {
    Write-Verbose "Creating backup at $BackupPath..."
    try {
        Copy-Item -Path $HostsPath -Destination $BackupPath -Force -ErrorAction Stop
        Write-Verbose "Backup created successfully"
        return $true
    }
    catch {
        Write-Error "Failed to create backup at $BackupPath`: $_"
        return $false
    }
}

function Invoke-DnsFlush {
    Write-Verbose "Flushing DNS cache..."
    & ipconfig /flushdns | Out-Null
    Write-Verbose "DNS cache flushed"
}

function Invoke-Rollback {
    if (-not (Test-Path $BackupPath)) {
        Write-Error "Backup file not found at $BackupPath. Cannot rollback."
        exit 1
    }

    if ($WhatIfPreference) {
        Write-Host "What if: Restoring hosts file from $BackupPath"
        return
    }

    if ($PSCmdlet.ShouldProcess($HostsPath, 'Restore from backup')) {
        Write-Host "Restoring hosts file from backup..."
        Copy-Item -Path $BackupPath -Destination $HostsPath -Force
        Write-Host "Rollback complete. DNS cache will be flushed."
        Invoke-DnsFlush
    }
}

# --- Main Execution ---

# Check for admin privileges
if (-not (Test-IsAdministrator)) {
    Write-Verbose "Not running as administrator. Self-elevating..."
    Invoke-SelfElevation
}

# Handle rollback
if ($Rollback) {
    Invoke-Rollback
    exit 0
}

# Fetch remote content
$remoteContent = Get-RemoteContent
if ($null -eq $remoteContent) {
    exit 1
}

# Validate content
if (-not (Test-ContentValid -Content $remoteContent)) {
    exit 1
}

# Read current hosts file
if (-not (Test-Path $HostsPath)) {
    Write-Error "Hosts file not found at $HostsPath"
    exit 1
}

$hostsContent = Get-Content -Path $HostsPath -Raw
$managedSection = Get-ManagedSection -HostsContent $hostsContent

# Check for changes (unless -Force)
if (-not $Force -and $null -ne $managedSection) {
    $localContent = Get-ManagedSectionContent -Section $managedSection.Content
    $localHash = Get-ContentHash -Content $localContent
    $remoteHash = Get-ContentHash -Content $remoteContent

    Write-Verbose "Local hash:  $localHash"
    Write-Verbose "Remote hash: $remoteHash"

    if ($localHash -eq $remoteHash) {
        Write-Host "Hosts file is already up to date. No changes detected."
        exit 0
    }

    Write-Host "Changes detected. Updating hosts file..."
}
else {
    if ($Force) {
        Write-Host "Force mode: skipping change detection."
    }
    else {
        Write-Host "First run: creating managed section..."
    }
}

# Build new managed section
$newSection = New-ManagedSection -Content $remoteContent

# WhatIf handling
if ($WhatIfPreference) {
    Write-Host "What if: Would update managed section in $HostsPath"
    Write-Host "What if: Would create backup at $BackupPath"
    Write-Host "What if: Would flush DNS cache"
    Write-Host ""
    Write-Host "Remote content preview (first 10 lines):"
    $remoteContent -split "`n" | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    exit 0
}

# Backup current hosts file
$backupSuccess = Backup-HostsFile
if (-not $backupSuccess) {
    Write-Error "Backup failed. Aborting to prevent data loss."
    exit 1
}

# Update hosts file
$newHostsContent = Update-HostsFile -HostsContent $hostsContent -NewSection $newSection

# Write updated content
try {
    $newHostsContent | Set-Content -Path $HostsPath -Encoding UTF8 -NoNewline -ErrorAction Stop
    Write-Host "Hosts file updated successfully."
}
catch {
    Write-Error "Failed to write hosts file: $_"
    Write-Host "Your hosts file was not modified. Backup is available at $BackupPath"
    exit 1
}

# Flush DNS
Invoke-DnsFlush

Write-Host "Done. GitHub520 hosts entries are now active."
