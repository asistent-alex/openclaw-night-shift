---
topic: Add GitHub release asset support to GRW
repo: grw
agent: dev-grw
type: feature
priority: medium
---

## Context

GRW (github-release-watch) currently only monitors release tags and notes. It doesn't track downloadable assets (binaries, packages, etc.) which are often the most important part of a release.

## Goal

Add asset tracking to GRW:
- Detect new/updated assets per release
- Report asset count, size, and download URL
- Support filtering by asset type (`.deb`, `.tar.gz`, etc.)
- Include asset info in email digest

## Implementation

1. Parse `assets` array from GitHub API response
2. Track asset metadata: `name`, `size`, `download_count`, `browser_download_url`
3. Add `--assets` flag to `grw watch` command
4. Include asset summary in email digest template
5. Store asset state in `.grw-state.json`

## Testing

- Test with repos that have assets (e.g., `cli/cli`, `docker/compose`)
- Verify asset count matches GitHub UI
- Ensure no regression for repos without assets

## Constraints

- **DO NOT MERGE PR automatically** — open PR and wait for human review
- Keep backward compatibility (existing behavior without `--assets`)
- Add tests for asset parsing
- Max ~150 lines changed

## Workflow

1. Create branch: `asset-support`
2. Implement asset parsing and tracking
3. Add `--assets` flag and tests
4. Open PR when done
5. Report PR URL and STOP — wait for human review
6. Do NOT merge — human will review and merge

## Acceptance Criteria

- [ ] `grw watch --assets` lists assets in output
- [ ] Asset info included in email digest
- [ ] State tracking detects new/updated assets
- [ ] Tests pass: `pytest tests/test_assets.py`
- [ ] README updated with `--assets` examples

---
Built by Firma de AI, supported by Firma de IT
https://firmade.ai | https://firmade.it
