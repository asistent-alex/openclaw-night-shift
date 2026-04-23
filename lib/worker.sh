#!/usr/bin/env bash
set -euo pipefail

# ── worker.sh — Spawn OpenClaw subagent to execute a mission ──
# Usage: worker.sh <mission_file> <config_file>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
MISSION_FILE="${1:-}"
CONFIG_FILE="${2:-${SCRIPT_DIR}/config.json}"

if [[ -z "$MISSION_FILE" || ! -f "$MISSION_FILE" ]]; then
  echo "❌ Missing mission file" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing config.json" >&2
  exit 1
fi

AGENT=$(jq -r '.agent' "$CONFIG_FILE")
BRANCH_PREFIX=$(jq -r '.branch_prefix // "night-shift"' "$CONFIG_FILE")
TODAY=$(date +%Y-%m-%d)
LOGS_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOGS_DIR"

# Extract mission fields
TOPIC=$(grep '^topic:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | head -1)
REPO_ALIAS=$(grep '^repo:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | head -1 || echo "")
TYPE=$(grep '^type:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | head -1 || echo "feature")
PRIORITY=$(grep '^priority:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | head -1 || echo "medium")

if [[ -z "$TOPIC" ]]; then
  TOPIC=$(basename "$MISSION_FILE" .md)
fi

BRANCH="${BRANCH_PREFIX}/${TODAY}-${TOPIC// /-}"
BRANCH="${BRANCH:0:50}"  # keep branch name reasonable

echo ""
echo "🚀 Night Shift Worker"
echo "   Agent: ${AGENT}"
echo "   Topic: ${TOPIC}"
echo "   Type: ${TYPE}"
echo "   Branch: ${BRANCH}"
echo ""

# Build the prompt for the subagent
# This integrates with prompt-to-pr skill workflow
PROMPT=$(cat <<EOF
You are the Night Shift worker. Execute the following mission using prompt-to-pr workflow.

MISSION:
$(cat "$MISSION_FILE")

YOUR TASK:
1. Research the topic via web search (2-3 searches max).
2. Summarize findings in 3-5 bullets.
3. Activate prompt-to-pr skill and implement:
   - Repo: ${REPO_ALIAS:-default}
   - Branch: ${BRANCH}
   - Mode: ${TYPE}
4. Open a PR with clear description referencing this night-shift mission.
5. Report back: PR URL, summary of changes, any blockers.

RULES:
- Follow prompt-to-pr phases: Clarify → Plan → APPROVE → Implement → Test → Verify → APPROVE → PR
- Keep changes focused and minimal.
- Add tests if applicable.
- Do NOT push to main directly.
- If stuck after 3 attempts, abort and report failure with reason.
- Update TASKS.md with progress before finishing.
EOF
)

echo "📝 Subagent prompt prepared (${#PROMPT} chars)"
echo "   Spawning via sessions_spawn..."
echo ""

# Create a task file for tracking
TASK_FILE="${LOGS_DIR}/task-${TODAY}-${TOPIC// /-}.md"
cat > "$TASK_FILE" <<EOF
# Night Shift Task — ${TODAY}

## Mission
${TOPIC}

## Prompt
${PROMPT}

## Branch
${BRANCH}

## Status
queued

## Started
$(date -Iseconds)
EOF

echo "   ✅ Task file created: ${TASK_FILE}"
echo ""
echo "   (Production call would be:)"
echo "   sessions_spawn --runtime subagent --mode run --agent ${AGENT} --task '${TASK_FILE}'"

# ── Output ──
cat <<EOF
{
  "status": "queued",
  "agent": "${AGENT}",
  "topic": "${TOPIC}",
  "branch": "${BRANCH}",
  "type": "${TYPE}",
  "task_file": "${TASK_FILE}",
  "prompt_length": ${#PROMPT}
}
EOF
