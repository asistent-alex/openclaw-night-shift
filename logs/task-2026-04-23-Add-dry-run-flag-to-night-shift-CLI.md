# Night Shift Task — 2026-04-23

## Mission
Add dry-run flag to night-shift CLI

## Prompt
You are the Night Shift worker. Execute the following mission using prompt-to-pr workflow.

MISSION:
---
date: 2026-04-23
repo: nexlink
topic: "Add dry-run flag to night-shift CLI"
type: feature
priority: low
---

## Context
The night-shift.sh script needs a --dry-run flag so users can preview what would happen without executing anything.

## Research Questions
1. How do other CLI tools implement dry-run flags?
2. What are best practices for dry-run output formatting?

## Implementation Notes
Add `--dry-run` flag parsing in night-shift.sh. When enabled, show what would be done but skip actual execution.

## Constraints
- Keep changes minimal (under 50 lines)
- Maintain backward compatibility
- No new dependencies needed

YOUR TASK:
1. Research the topic via web search (2-3 searches max).
2. Summarize findings in 3-5 bullets.
3. Activate prompt-to-pr skill and implement:
   - Repo: nexlink
   - Branch: night-shift/2026-04-23-Add-dry-run-flag-to-night-s
   - Mode: feature
4. Open a PR with clear description referencing this night-shift mission.
5. Report back: PR URL, summary of changes, any blockers.

RULES:
- Follow prompt-to-pr phases: Clarify → Plan → APPROVE → Implement → Test → Verify → APPROVE → PR
- Keep changes focused and minimal.
- Add tests if applicable.
- Do NOT push to main directly.
- If stuck after 3 attempts, abort and report failure with reason.
- Update TASKS.md with progress before finishing.

## Branch
night-shift/2026-04-23-Add-dry-run-flag-to-night-s

## Status
queued

## Started
2026-04-23T15:21:09+00:00
