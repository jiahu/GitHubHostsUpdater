# 04 — Change detection, backup, and update managed section

**What to build:** The complete update cycle: compute SHA256 hash of remote content, compare against local managed section, create `.bak` backup, replace the managed section with new content, and flush DNS cache.

**Blocked by:** 02-fetch-validate, 03-parse-create

**Status:** done

- [x] SHA256 hash comparison for change detection
- [x] Create .bak backup before modification (with error handling)
- [x] Replace managed section with new content
- [x] Flush DNS cache via ipconfig /flushdns
- [x] Skip update if hashes match (unless -Force)
- [x] WhatIf dry-run mode shows what would change
