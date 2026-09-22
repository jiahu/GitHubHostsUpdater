---
Status: ready-for-agent
Created: 2026-09-22
---

# GitHub520 Hosts Updater - Specification

## Problem Statement

GitHub access in certain networks (particularly in China) is often slow or unreliable due to DNS pollution or IP blocking. The GitHub520 project maintains a hosts file that maps GitHub domains to optimized IP addresses, but manually updating this file is tedious and error-prone. Users need an automated way to keep their local hosts file synchronized with the remote GitHub520 source, ensuring consistent GitHub access without manual intervention.

## Solution

A PowerShell script that runs daily (via Windows Task Scheduler) to fetch the latest hosts entries from the GitHub520 project, compare them against the current local hosts file, and update only the managed section if changes are detected. The script operates safely by creating backups, validating content before writing, and isolating GitHub520 entries from user-customized hosts entries using section markers.

## User Stories

1. As a developer in a restricted network, I want my hosts file to automatically update with GitHub520 entries daily, so that I have reliable GitHub access without manual intervention
2. As a system administrator, I want the script to run unattended via Task Scheduler, so that it doesn't require user interaction or disrupt workflow
3. As a user with custom hosts entries (local dev domains, ad blockers), I want the script to only modify the GitHub520 section, so that my custom entries remain untouched
4. As a cautious user, I want the script to create a backup before modifying the hosts file, so that I can recover if something goes wrong
5. As a user troubleshooting network issues, I want to be able to rollback the last update, so that I can test whether the GitHub520 entries are causing problems
6. As a power user, I want to run the script manually with verbose logging, so that I can diagnose issues when they occur
7. As a user testing the script, I want a dry-run mode that simulates the update without modifying files, so that I can verify the script works correctly before deploying it
8. As a user with a first-time setup, I want the script to automatically create the managed section on first run, so that I don't need to manually edit the hosts file
9. As a security-conscious user, I want the script to validate the fetched content before writing, so that malformed or malicious data doesn't corrupt my hosts file
10. As a user experiencing network issues, I want the script to handle fetch failures gracefully, so that my hosts file isn't corrupted when the remote source is unavailable
11. As a user running the script, I want clear console output showing what the script is doing, so that I can understand its behavior and diagnose problems
12. As a script maintainer, I want the managed section to include a timestamp in the marker, so that I can visually verify when the section was last updated
13. As a user with administrator privileges, I want the script to self-elevate if needed, so that I don't need to remember to run it as administrator
14. As a user who wants to force an update, I want a parameter to skip change detection, so that I can refresh the hosts file even if the content hasn't changed
15. As a user reading the script documentation, I want PowerShell inline help, so that I can quickly reference parameters and examples using `Get-Help`
16. As a new user setting up the script, I want a README with installation instructions, so that I can configure Task Scheduler and understand how the script works
17. As a user verifying the script's behavior, I want the script to flush the DNS cache after updating, so that the new hosts entries take effect immediately
18. As a user concerned about script dependencies, I want the script to work with built-in PowerShell features only, so that I don't need to install additional modules
19. As a user running the script on different Windows versions, I want compatibility with PowerShell 5.1+, so that it works on Windows 10 and 11 without requiring PowerShell 7
20. As a user reviewing the script's logic, I want the change detection to use content hashing (SHA256), so that it reliably detects actual changes without false positives

## Implementation Decisions

### Managed Section Strategy
The script maintains a delimited section within the hosts file using `# BEGIN GitHub520 (YYYY-MM-DD)` and `# END GitHub520` markers. Only content between these markers is modified. This isolates GitHub520 entries from user-customized entries and makes the script idempotent.

On first run (no markers present), the script appends the managed section at the end of the hosts file with the fetched content.

### Change Detection
SHA256 hash comparison is used to detect changes. The script computes the hash of the fetched remote content and compares it against the hash of the current managed section content (excluding the marker lines themselves). If hashes match, no update is performed. The `-Force` parameter bypasses this check.

### Backup Strategy
A single backup file (`hosts.bak`) is created in the same directory as the hosts file immediately before any modification. The backup is overwritten on each update. This provides a manual rollback point without cluttering the directory with multiple backups.

### Content Validation
Before writing, the script validates that the fetched content:
- Is non-empty
- Contains at least one valid hosts entry (line matching pattern: IP address followed by domain)
- Does not contain HTML error pages (e.g., `<html>`, `<!DOCTYPE`)

If validation fails, the script aborts with a warning and does not modify the hosts file.

### Self-Elevation
The script checks for administrator privileges at startup using `([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)`. If not elevated, it re-launches itself using `Start-Process -FilePath $PSHOME -Verb RunAs` with the original arguments.

### DNS Cache Flush
After a successful update, the script executes `ipconfig /flushdns` to force the OS to discard cached DNS lookups and use the updated hosts file immediately.

### Error Handling
- **Network failure**: Print error message to console, exit with non-zero code. No retry logic (next daily run will retry automatically).
- **Malformed content**: Print warning, abort without modifying hosts file.
- **Missing backup on rollback**: Print error message, no action.
- **Permission denied**: Self-elevation handles this; if elevation fails, script exits with error.

### PowerShell Version
Target PowerShell 5.1+ (built into Windows 10/11). No external module dependencies. All required cmdlets (`Invoke-WebRequest`, `Get-FileHash`, file I/O) are available in 5.1.

### Script Parameters
- `-WhatIf` (built-in): Dry-run mode. Simulates all operations without modifying files.
- `-Verbose` (built-in): Detailed logging of each step.
- `-Force`: Skip change detection, always update.
- `-Rollback`: Restore hosts file from `.bak` backup.

### Documentation
- **README.md**: Installation instructions, Task Scheduler setup, usage examples, troubleshooting.
- **Inline PowerShell help**: Comment-based help block at the top of the script, accessible via `Get-Help .\update-github520-hosts.ps1 -Detailed`.

### File Paths
- Script: `update-github520-hosts.ps1` in the repository root
- Hosts file: `C:\Windows\System32\drivers\etc\hosts`
- Backup file: `C:\Windows\System32\drivers\etc\hosts.bak`

### Task Scheduler Configuration
- Trigger: Daily at 3:47 AM
- Action: Run `powershell.exe -ExecutionPolicy Bypass -File "path\to\update-github520-hosts.ps1"`
- Security: "Run with highest privileges" enabled
- Conditions: "Start the task only if the computer is on AC power" (optional, configurable)

## Testing Decisions

### What Makes a Good Test
Tests should verify external behavior (inputs and outputs), not implementation details. For a PowerShell script that modifies system files, the highest-value tests are:
1. **Integration tests** using `-WhatIf` to verify the script's logic without modifying the actual hosts file
2. **Unit tests** for individual functions (fetch, validate, compare, parse markers) using Pester

### Test Strategy
- **Dry-run testing**: Run the script with `-WhatIf` to verify it fetches content, detects changes, and would update correctly without actually modifying the hosts file. This is the primary validation method.
- **Unit tests (optional)**: If Pester is available, write tests for:
  - Content validation (valid hosts entries, malformed content, empty content)
  - Marker parsing (extract managed section, handle missing markers)
  - Hash comparison (detect changes, handle identical content)
  - Backup creation and rollback

### Prior Art
This is a new project with no existing tests. The `-WhatIf` dry-run is the primary testing mechanism. Pester unit tests are optional and can be added if the script grows in complexity.

## Out of Scope

- **Cross-platform support**: This script is Windows-only (PowerShell 5.1+). Linux/macOS hosts file management is out of scope.
- **Multiple remote sources**: Only the GitHub520 project URL is supported. Configuring multiple sources is out of scope.
- **Automated testing CI/CD**: No automated test pipeline. Manual testing via `-WhatIf` is sufficient for this use case.
- **Rollback automation beyond `.bak`**: No versioned backups, no cloud sync, no git integration. Single `.bak` file only.
- **Network retry logic**: No exponential backoff or retry on network failure. The next daily run serves as the retry.
- **GUI or toast notifications**: Console output only. No system tray icon, no desktop notifications.
- **Hosts file syntax validation**: The script validates that content looks like hosts entries but does not perform full syntax validation (e.g., checking for valid IP addresses, valid domain names).
- **Conflict detection**: The script does not check for conflicts between GitHub520 entries and existing user entries outside the managed section.
- **Scheduled task creation automation**: The README will document how to create the Task Scheduler task manually. The script does not create the task itself.

## Further Notes

### Security Considerations
- The script downloads content from a public GitHub URL. Users should verify the URL is correct and trust the GitHub520 project.
- The script requires administrator privileges to modify the hosts file. Self-elevation via UAC is the recommended approach.
- The `.bak` file contains the previous hosts file contents. Users should be aware of this and secure the file if needed.

### Performance
- The script performs a single HTTP GET request per run. Typical execution time is 1-3 seconds.
- SHA256 hashing is fast and adds negligible overhead.
- DNS cache flush takes ~100ms.

### Maintenance
- If the GitHub520 project URL changes, update the `$SourceUrl` variable in the script.
- If the marker format changes, existing managed sections will not be recognized. Users would need to manually remove the old section or the script will create a new one.

### Troubleshooting
- **Script doesn't update**: Check network connectivity, verify the remote URL is accessible, run with `-Verbose` for details.
- **Hosts file not modified**: Verify the script is running with administrator privileges. Check the console output for validation errors.
- **DNS not resolving correctly**: Manually run `ipconfig /flushdns` or reboot the machine.
- **Rollback needed**: Run the script with `-Rollback` or manually copy `hosts.bak` to `hosts`.
