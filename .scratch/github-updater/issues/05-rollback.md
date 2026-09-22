# 05 — Rollback operation

**What to build:** The `-Rollback` parameter restores the hosts file from the `.bak` backup. If no backup exists, prints an error and exits.

**Blocked by:** 04-update-cycle

**Status:** done

- [x] Restore hosts file from .bak backup
- [x] Error handling if backup doesn't exist
- [x] WhatIf dry-run mode for rollback
- [x] Flush DNS cache after rollback
