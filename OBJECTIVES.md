# Night Shift — Objectives & Success Criteria

## System Mission

> **Night Shift is an autonomous development pipeline that executes low-risk tasks overnight while the human is unavailable. Agents create Pull Requests for morning review — they never merge without explicit human approval.**

## Agent: dev-nexlink

> **Maintain and improve the NexLink OpenClaw skill. Fix bugs, add features, improve test coverage, keep documentation current. All changes delivered via PR for human review.**

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Tasks completed per night | 1-3 | `git log --since="yesterday" --oneline` |
| PRs opened vs merged by agent | 100% / 0% | GitHub API |
| Test coverage trend | +5% per month | `pytest --cov` |
| Bugs introduced by agent | 0 | Post-merge incident tracking |
| Morning review time | <15 min/PR | Human feedback |

## Constraints (Hard Rules)

1. **NEVER auto-merge** — PR opened → STOP → human reviews
2. **No production secrets** — agent works with test configs only
3. **No destructive changes** — no `rm`, `drop`, `delete` without approval
4. **Test before PR** — `pytest` must pass before opening PR
5. **Max 500 lines changed per PR** — keep reviews manageable

## Escalation

Agent is blocked and stops when:
- Tests fail and can't be fixed in 3 attempts
- External API changes break integration
- Security concerns detected
- Unclear requirements

Human reviews every morning and decides:
- Merge / Request changes / Close PR

---
Built by Firma de AI, supported by Firma de IT
https://firmade.ai | https://firmade.it
