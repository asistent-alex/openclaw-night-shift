# openclaw-night-shift

> Orchestrated overnight coding — wake up to PRs.

AI agent that researches and implements features while you sleep. Built for OpenClaw.

Built by [Firma de AI](https://firmade.ai), supported by [Firma de IT](https://firmade.it).

## Quick Start

```bash
# 1. Clone
git clone https://github.com/asistent-alex/openclaw-night-shift.git
cd openclaw-night-shift

# 2. Configure
cp config.example.json config.json
# Edit: add your repo, email, OpenClaw agent

# 3. Queue a mission
cp missions/TEMPLATE.md missions/2026-04-23-my-feature.md
# Edit: describe what you want researched/built

# 4. Run (or wait for cron)
./night-shift.sh --dry-run
./night-shift.sh
```

## How It Works

```
22:00 — cron starts night-shift.sh
   ↓
Reads missions/*.md
   ↓
For each mission:
  1. Research (web search + synthesis)
  2. Spawn OpenClaw subagent with context
  3. Subagent runs prompt-to-pr workflow
  4. Branch: night-shift/YYYY-MM-DD-topic
  5. PR opened on GitHub
   ↓
07:00 — email digest via NexLink
   ↓
You: review PR → approve / close
```

## Features

- [x] Research-first: web search before coding
- [x] Isolated subagents: one mission = one clean context
- [x] Branch per mission: zero risk to main
- [x] Morning digest: email summary of what happened
- [x] Dry-run mode: preview without executing
- [ ] Token budget tracking (Phase 2)
- [ ] Iterative execution (Phase 2)
- [ ] Task taxonomy: lint-fix, test-gap, doc-drift (Phase 3)
- [ ] CI monitoring: wait for checks before email (Phase 3)

## Architecture

```
night-shift.sh          # orchestrator (cron entry)
config.json             # repos, schedule, email, agent
missions/               # you write these
  TEMPLATE.md
  2026-04-23-*.md
lib/
  research.sh           # web search + synthesis
  worker.sh             # spawn subagent + prompt-to-pr
  reporter.sh           # email digest via nexlink
logs/                   # one per night
TASKS.md                # memory between iterations
```

## Requirements

- OpenClaw with `prompt-to-pr` skill
- `nexlink` skill for email
- `gh` CLI for PRs
- Cron (or systemd timer)

## License

MIT — see LICENSE.
