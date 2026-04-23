#!/usr/bin/env bash
set -euo pipefail

# ── worker.sh — Dispatch mission to dedicated OpenClaw agent ──
# Usage: worker.sh <mission_file> <config_file>
# All informational output goes to stderr; JSON result goes to stdout

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

TODAY=$(date +%Y-%m-%d)
LOGS_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOGS_DIR"

BRANCH_PREFIX=$(jq -r '.branch_prefix // "night-shift"' "$CONFIG_FILE")

# Extract mission fields
TOPIC=$(grep '^topic:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//; s/^"//; s/"$//' | head -1)
REPO_ALIAS=$(grep '^repo:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//; s/^"//; s/"$//' | head -1 || echo "")
TYPE=$(grep '^type:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//; s/^"//; s/"$//' | head -1 || echo "feature")
PRIORITY=$(grep '^priority:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//; s/^"//; s/"$//' | head -1 || echo "medium")

if [[ -z "$TOPIC" ]]; then
  TOPIC=$(basename "$MISSION_FILE" .md)
fi

# Fallback repo
if [[ -z "$REPO_ALIAS" ]]; then
  REPO_ALIAS=$(jq -r '.repos[] | select(.default == true) | .alias' "$CONFIG_FILE" | head -1 || echo "nexlink")
fi

BRANCH="${BRANCH_PREFIX}/${TODAY}-${TOPIC// /-}"
BRANCH="${BRANCH:0:50}"

# Resolve agent from config mapping
AGENT_NAME=$(jq -r --arg repo "$REPO_ALIAS" '.agents[$repo] // .agents.default // "main"' "$CONFIG_FILE")

# Resolve repo path
REPO_PATH=$(jq -r --arg alias "$REPO_ALIAS" '.repos[] | select(.alias == $alias) | .path' "$CONFIG_FILE" | head -1 || echo "")
if [[ -z "$REPO_PATH" || "$REPO_PATH" == "null" ]]; then
  # Try expanding ~ manually
  REPO_PATH="${HOME}/.openclaw/skills/${REPO_ALIAS}"
fi

# Resolve absolute path for task file
MISSION_ABS="$(cd "$(dirname "$MISSION_FILE")" && pwd)/$(basename "$MISSION_FILE")"

# Create concise task file for agent
TASK_FILE="${LOGS_DIR}/task-${TODAY}-${TOPIC// /-}.md"
cat > "$TASK_FILE" <<EOF
# Night Shift Mission — ${TODAY}

## Topic
${TOPIC}

## Repo
${REPO_ALIAS} → ${REPO_PATH}

## Branch
${BRANCH}

## Type
${TYPE}

## Priority
${PRIORITY}

## Full Mission File
${MISSION_ABS}

## Instructions
1. Read the full mission file above
2. Use prompt-to-pr skill to implement
3. Branch from main: ${BRANCH}
4. Open PR when done
5. Report: PR URL, summary, any blockers

## Context
- You are dev agent ${AGENT_NAME}
- This task was dispatched by Night Shift orchestrator
- Execute autonomously, ask user only if truly blocked
EOF

echo "" >&2
echo "🚀 Night Shift Worker" >&2
echo "   Agent: ${AGENT_NAME}" >&2
echo "   Topic: ${TOPIC}" >&2
echo "   Repo: ${REPO_ALIAS} (${REPO_PATH})" >&2
echo "   Branch: ${BRANCH}" >&2
echo "   Type: ${TYPE}" >&2
echo "" >&2

# Build concise message for agent
MESSAGE=$(cat <<EOF
Night Shift mission: ${TOPIC}
Repo: ${REPO_ALIAS} at ${REPO_PATH}
Branch: ${BRANCH}
Type: ${TYPE}

Read task file: ${TASK_FILE}
Then execute using prompt-to-pr skill.
EOF
)

echo "📤 Dispatching to agent ${AGENT_NAME}..." >&2

# Dispatch to agent in background — non-blocking
AGENT_LOG="${LOGS_DIR}/agent-${TODAY}-${TOPIC// /-}.log"
AGENT_PID_FILE="${LOGS_DIR}/agent-${TODAY}-${TOPIC// /-}.pid"

# Use nohup to survive session termination
nohup bash -c "
  openclaw agent \
    --agent ${AGENT_NAME} \
    --message \"$(echo "$MESSAGE" | sed 's/"/\\"/g')\" \
    --timeout 3600 \
    > \"${AGENT_LOG}\" 2>&1 \
    || echo 'AGENT_EXITED_WITH_ERROR' >> \"${AGENT_LOG}\"
  echo \"AGENT_FINISHED at \$(date -Iseconds)\" >> \"${AGENT_LOG}\"
" >/dev/null 2>&1 &

AGENT_PID=$!
echo "$AGENT_PID" > "$AGENT_PID_FILE"

echo "   ✅ Agent PID: ${AGENT_PID}" >&2
echo "   📝 Log: ${AGENT_LOG}" >&2

# Update TASKS.md
"${SCRIPT_DIR}/lib/tasks.sh" add "${TODAY}" "${TOPIC}" "${BRANCH}" "${AGENT_NAME}" "${TYPE}" >/dev/null 2>&1 || true
"${SCRIPT_DIR}/lib/tasks.sh" update "${BRANCH}" status "dispatched_to_agent" >/dev/null 2>&1 || true
"${SCRIPT_DIR}/lib/tasks.sh" update "${BRANCH}" result "PID:${AGENT_PID}" >/dev/null 2>&1 || true

echo "" >&2
echo "   ✅ Mission dispatched. Agent working in background." >&2
echo "   ⏱️  Max runtime: 1 hour" >&2

# ── Output JSON ──
jq -n \
  --arg agent "$AGENT_NAME" \
  --arg topic "$TOPIC" \
  --arg repo "$REPO_ALIAS" \
  --arg branch "$BRANCH" \
  --arg type "$TYPE" \
  --arg task_file "$TASK_FILE" \
  --arg pid "$AGENT_PID" \
  --arg log "$AGENT_LOG" \
  '{
    status: "dispatched_to_agent",
    agent: $agent,
    topic: $topic,
    repo: $repo,
    branch: $branch,
    type: $type,
    task_file: $task_file,
    pid: $pid,
    log: $log
  }'
