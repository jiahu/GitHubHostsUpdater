# Context

## Glossary

**Remote source**  
The GitHub520 hosts file hosted at `https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts`. Contains IP-to-domain mappings maintained by the GitHub520 project to improve GitHub access in restricted networks.

**Local hosts file**  
The Windows system hosts file at `C:\Windows\System32\drivers\etc\hosts`. Maps hostnames to IP addresses before DNS resolution. Requires administrator privileges to modify.

**Managed section**  
A delimited region within the local hosts file, marked by `# BEGIN GitHub520` and `# END GitHub520` comments. The script exclusively modifies this section, leaving all other entries (custom domains, ad blockers, etc.) untouched.

**Backup file**  
A single `.bak` copy of the local hosts file (e.g., `hosts.bak`) created immediately before any modification. Overwritten on each update. Provides a manual rollback point.

**Content hash**  
A SHA256 digest of the managed section's content. Used to detect changes between the remote source and the local managed section. If hashes match, no update is performed.

**Section markers**  
Two comment lines (`# BEGIN GitHub520` and `# END GitHub520`) that delimit the managed section. The script searches for these markers to locate, extract, or replace the managed section.

**Self-elevation**  
The script's ability to detect when it's running without administrator privileges and re-launch itself with elevated permissions via UAC prompt. Ensures the script can write to the protected hosts file.

**DNS cache flush**  
The execution of `ipconfig /flushdns` after a successful hosts file update. Forces the OS to discard cached DNS lookups and use the updated hosts file immediately.

**Dry-run mode**  
Execution with the `-WhatIf` parameter. The script simulates all operations (fetch, compare, backup, write) without modifying any files. Used for safe testing before deployment.

**Rollback operation**  
Restoration of the hosts file from the `.bak` backup. Triggered by the `-Rollback` parameter or manual file copy. Reverses the last update.

**Content validation**  
Pre-write checks ensuring the fetched remote content is well-formed: non-empty, contains at least one valid hosts entry (IP address + domain), and doesn't contain HTML error pages or other malformed data.

**Self-elevation**  
The script's ability to detect when it's running without administrator privileges and re-launch itself with elevated permissions via UAC prompt. Ensures the script can write to the protected hosts file.
