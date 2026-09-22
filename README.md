# GitHub Hosts Updater

[中文文档](README.zh-CN.md)

Automatically update your Windows hosts file with [GitHub520](https://github.com/521xueweihan/GitHub520) project entries to improve GitHub access in restricted networks.

## What It Does

- Fetches the latest hosts entries from the GitHub520 project
- Updates only a managed section in your hosts file (preserves your custom entries)
- Creates a backup before each update
- Flushes DNS cache to apply changes immediately
- Runs daily via Windows Task Scheduler

## Requirements

- Windows 10 or 11
- PowerShell 5.1+ (built-in)
- Administrator privileges (script will self-elevate if needed)

## Installation

1. **Download the script** to a location on your computer:

   ```powershell
   # Example: save to your user scripts folder
   mkdir "$env:USERPROFILE\Scripts" -ErrorAction SilentlyContinue
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jiahu/GitHubHostsUpdater/main/src/update-github-hosts.ps1" -OutFile "$env:USERPROFILE\Scripts\update-github-hosts.ps1"
   ```

   Or clone this repository:
   ```powershell
   git clone https://github.com/jiahu/GitHubHostsUpdater.git
   ```

2. **Test the script** in dry-run mode:

   ```powershell
   .\update-github-hosts.ps1 -WhatIf
   ```

   This shows what would happen without modifying your hosts file.

3. **Run the script** manually (first time):

   ```powershell
   .\update-github-hosts.ps1 -Verbose
   ```

   The script will:
   - Self-elevate to administrator if needed (UAC prompt)
   - Fetch the latest GitHub520 hosts entries
   - Create a managed section in your hosts file (first run)
   - Create a backup at `C:\Windows\System32\drivers\etc\hosts.bak`
   - Flush your DNS cache

## Usage

### Basic Update
```powershell
.\update-github-hosts.ps1
```

Runs the update. If the remote content has changed, updates the managed section.

### Dry-Run Mode
```powershell
.\update-github-hosts.ps1 -WhatIf
```

Shows what would happen without modifying any files. Useful for testing.

### Verbose Logging
```powershell
.\update-github-hosts.ps1 -Verbose
```

Shows detailed information about each step (fetching, comparing, updating).

### Force Update
```powershell
.\update-github-hosts.ps1 -Force
```

Skips change detection and updates even if the content hasn't changed.

### Rollback
```powershell
.\update-github-hosts.ps1 -Rollback
```

Restores your hosts file from the backup (`hosts.bak`). Useful if the GitHub520 entries cause issues.

You can also rollback manually:
```powershell
Copy-Item "C:\Windows\System32\drivers\etc\hosts.bak" "C:\Windows\System32\drivers\etc\hosts" -Force
ipconfig /flushdns
```

## Setting Up Daily Automation

Use Windows Task Scheduler to run the script daily at 3:47 AM:

### Method 1: PowerShell Script (Recommended)

Save this as `setup-task.ps1` and run it as administrator:

```powershell
$scriptPath = "D:\Tools\GitHubHosts\src\update-github-hosts.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -Daily -At "3:47am"

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "GitHub Hosts Updater" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Description "Updates hosts file with GitHub520 entries daily"
```

### Method 2: Task Scheduler GUI

1. Open Task Scheduler (search for it in Start menu)
2. Click "Create Task" (not "Create Basic Task")
3. **General tab**:
   - Name: `GitHub Hosts Updater`
   - Check "Run with highest privileges"
   - Configure for: Windows 10
4. **Triggers tab**:
   - Click "New"
   - Settings: Daily, 3:47 AM
   - Check "Enabled"
5. **Actions tab**:
   - Click "New"
   - Action: Start a program
   - Program/script: `powershell.exe`
   - Add arguments: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\Tools\GitHubHosts\src\update-github-hosts.ps1"`
6. **Conditions tab**:
   - Uncheck "Start the task only if the computer is on AC power" (optional)
7. Click "OK"

## How It Works

### Managed Section

The script maintains a delimited section in your hosts file:

```
# BEGIN GitHub520 (2026-09-22)
140.82.114.4    github.com
192.30.255.116  api.github.com
# ... more entries ...
# END GitHub520
```

Only the content between `# BEGIN GitHub520` and `# END GitHub520` is modified. All other entries in your hosts file (custom domains, ad blockers, local dev environments) remain untouched.

### Change Detection

The script computes a SHA256 hash of the remote content and compares it against the local managed section. If hashes match, no update is performed (unless `-Force` is used).

### Backup

Before each update, the script creates a backup at `C:\Windows\System32\drivers\etc\hosts.bak`. This is a single file that's overwritten on each update. Use `-Rollback` to restore from this backup.

## Troubleshooting

### Script doesn't update
- Check your network connection
- Verify the remote URL is accessible: `Invoke-WebRequest https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts`
- Run with `-Verbose` to see detailed error messages

### Hosts file not modified
- Ensure the script is running with administrator privileges
- Check if antivirus or security software is blocking the modification
- Look for validation error messages in the console output

### DNS not resolving correctly after update
- Manually flush DNS: `ipconfig /flushdns`
- Restart your browser or network adapter
- Reboot the machine if needed

### Rollback needed
```powershell
.\update-github-hosts.ps1 -Rollback
```

Or manually:
```powershell
Copy-Item "C:\Windows\System32\drivers\etc\hosts.bak" "C:\Windows\System32\drivers\etc\hosts" -Force
ipconfig /flushdns
```

### Task Scheduler not running
- Open Task Scheduler and check the task status
- Verify the task is set to "Run with highest privileges"
- Check the task history for error messages
- Ensure the script path is correct

## Security Notes

- The script downloads content from a public GitHub URL. Verify the URL is correct and trust the GitHub520 project.
- The script requires administrator privileges to modify the hosts file.
- The `.bak` file contains your previous hosts file contents. Secure it if needed.
- Review the script source code before running it to ensure you understand what it does.

## License

This script is provided as-is for personal use. The GitHub520 project is maintained by [521xueweihan](https://github.com/521xueweihan/GitHub520).

## Support

For issues with the GitHub520 hosts entries themselves, visit the [GitHub520 project](https://github.com/521xueweihan/GitHub520).

For issues with this script, check the troubleshooting section above or [file an issue](https://github.com/jiahu/GitHubHostsUpdater/issues) in the [GitHub Hosts Updater repository](https://github.com/jiahu/GitHubHostsUpdater).
