# 03 — Parse markers and create managed section on first run

**What to build:** The script can detect the `# BEGIN GitHub520` / `# END GitHub520` markers in the hosts file. On first run (no markers present), it appends a new managed section at the end of the hosts file.

**Blocked by:** 01-script-skeleton

**Status:** done

- [x] Parse existing managed section from hosts file
- [x] Detect markers using regex (with constants, not hardcoded strings)
- [x] Append new managed section on first run (no markers present)
- [x] Include timestamp in marker: `# BEGIN GitHub520 (YYYY-MM-DD)`
