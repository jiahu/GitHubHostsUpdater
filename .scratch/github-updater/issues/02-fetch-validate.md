# 02 — Fetch and validate remote hosts content

**What to build:** The script can fetch hosts content from the GitHub520 URL, validate it's well-formed (non-empty, contains valid hosts entries, no HTML errors), and display the fetched content to console.

**Blocked by:** 01-script-skeleton

**Status:** done

- [x] Fetch remote content via Invoke-WebRequest
- [x] Validate content is non-empty
- [x] Validate content contains at least one valid hosts entry
- [x] Validate content is not an HTML error page
- [x] Graceful error handling on network failure
