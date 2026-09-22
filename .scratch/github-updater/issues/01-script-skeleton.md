# 01 — Script skeleton with self-elevation and parameter handling

**What to build:** A runnable PowerShell script that accepts `-Verbose`, `-WhatIf`, `-Force`, and `-Rollback` parameters. Self-elevates to administrator if needed.

**Blocked by:** None — can start immediately

**Status:** done

- [x] Script accepts -Verbose, -WhatIf, -Force, -Rollback parameters
- [x] Self-elevation to administrator via UAC
- [x] PowerShell 5.1+ compatible (no external dependencies)
- [x] Comment-based help (Get-Help support)
