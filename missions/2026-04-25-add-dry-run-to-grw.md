---
topic: Add dry-run mode to GRW
repo: grw
agent: dev-grw
type: refactor
priority: high
---

## Context

GRW currently modifies state and sends emails immediately. There's no way to preview what it will do without actually doing it, which makes testing risky.

## Goal

Add `--dry-run` flag to all GRW commands that preview changes without applying them.

## Scope

Commands needing `--dry-run`:
- `grw watch` — show what emails would be sent
- `grw email` — show email content without sending
- `grw cleanup` — show what old records would be removed

## Implementation

1. Add `--dry-run` flag to CLI parser
2. When enabled, log all actions but skip mutations:
   - Don't write `.grw-state.json`
   - Don't send emails
   - Don't delete old records
3. Add `DRY_RUN=true` to output header so user knows it's preview
4. Exit code 0 (not error) to allow CI integration

## Testing

- Test with `--dry-run` vs normal run
- Verify state file unchanged after dry-run
- Verify no emails sent during dry-run
- Ensure exit code is 0

## Constraints

- **DO NOT MERGE PR automatically** — open PR and wait for human review
- Keep normal behavior unchanged (default: not dry-run)
- Add tests for dry-run mode
- Max ~100 lines changed

## Workflow

1. Create branch: `dry-run`
2. Add `--dry-run` to each command
3. Implement skip-logic for mutations
4. Open PR when done
5. Report PR URL and STOP — wait for human review
6. Do NOT merge — human will review and merge

## Acceptance Criteria

- [ ] `grw watch --dry-run` shows preview without state changes
- [ ] `grw email --dry-run` shows email without sending
- [ ] `grw cleanup --dry-run` shows deletions without removing
- [ ] Tests pass: `pytest tests/test_dry_run.py`
- [ ] README updated with `--dry-run` examples

---
Built by Firma de AI, supported by Firma de IT
https://firmade.ai | https://firmade.it
