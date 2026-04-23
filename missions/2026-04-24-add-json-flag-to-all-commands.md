---
topic: Add --json flag to all nexlink commands for consistent output
repo: nexlink
agent: dev-nexlink
type: refactor
priority: medium
---

## Context

Right now nexlink commands output text/tables inconsistently. Some commands have `--json`, others don't. This makes it hard to script around nexlink.

## Goal

Add `--json` flag to ALL commands in nexlink:
- `exchange inbox/list/send/draft/reply`
- `nextcloud files/info/shared`
- `sync status/now`
- `analytics stats/contacts/tasks`

## Implementation

1. Each command should accept `--json` flag
2. When `--json` is used, output valid JSON (no tables, no colors)
3. When not used, keep current human-friendly output
4. Use `json` module for serialization (not string concatenation)
5. Handle errors as JSON too: `{"error": "message", "code": 1}`

## Testing

- Test each command with and without `--json`
- Verify output is valid JSON (can parse with `python -m json.tool`)
- Ensure non-JSON mode still works (no regression)

## Acceptance Criteria

- [ ] All commands accept `--json`
- [ ] `--json` output is valid parseable JSON
- [ ] No regression in default (human-friendly) mode
- [ ] README updated with `--json` examples
- [ ] CHANGELOG updated

---
Built by Firma de AI, supported by Firma de IT
https://firmade.ai | https://firmade.it
