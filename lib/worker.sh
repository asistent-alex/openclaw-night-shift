#!/usr/bin/env bash
set -euo pipefail

# ── worker.sh — Prepare mission for OpenClaw subagent dispatch ──
# This script NO LONGER does nohup/openclaw agent.
# It creates a task file that the main session reads and spawns via sessions_spawn.
#
# Usage: worker.sh <mission_file> <config_file>
# All informational output goes to stderr; JSON result goes to stdout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
MISSION_FILE="${1:-}"
CONFIG_FILE="${2:-${SCRIPT_DIR}/config.json}"

if [[ -z "$MISSION_FILE" || ! -f "$MISSION_FILE" ]]; then
  echo '{"error":"Missing or invalid mission file"}' >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo '{"error":"Missing config.json"}' >&2
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
LOGS_DIR="${SCRIPT_DIR}/logs"
QUEUE_DIR="${SCRIPT_DIR}/queue"
mkdir -p "$LOGS_DIR" "$QUEUE_DIR"

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

# Resolve agent from config mapping
AGENT_NAME=$(jq -r --arg repo "$REPO_ALIAS" '.agents[$repo] // .agents.default // "main"' "$CONFIG_FILE")

# Resolve repo path
REPO_PATH=$(jq -r --arg alias "$REPO_ALIAS" '.repos[] | select(.alias == $alias) | .path' "$CONFIG_FILE" | head -1 || echo "")
if [[ -z "$REPO_PATH" || "$REPO_PATH" == "null" ]]; then
  REPO_PATH="${HOME}/.openclaw/skills/${REPO_ALIAS}"
fi

BRANCH="${BRANCH_PREFIX}/${TODAY}-${TOPIC// /-}"
BRANCH="${BRANCH:0:50}"

MISSION_ABS="$(cd "$(dirname "$MISSION_FILE")" && pwd)/$(basename "$MISSION_FILE")"

# Build queue file path
QUEUE_FILE="${QUEUE_DIR}/$(date +%s)-${TODAY}-${TOPIC// /-}.json"

# Write queue file as JSON — easy for the AI to parse
jq -n \
  --arg agent "$AGENT_NAME" \
  --arg topic "$TOPIC" \
  --arg repo_alias "$REPO_ALIAS" \
  --arg repo_path "$REPO_PATH" \
  --arg branch "$BRANCH" \
  --arg type "$TYPE" \
  --arg priority "$PRIORITY" \
  --arg mission_file "$MISSION_ABS" \
  --arg date "$TODAY" \
  '{
    agent: $agent,
    topic: $topic,
    repo_alias: $repo_alias,
    repo_path: $repo_path,
    branch: $branch,
    type: $type,
    priority: $priority,
    mission_file: $mission_file,
    date: $date,
    status: "pending"
  }' > "$QUEUE_FILE"

echo "" >&2
echo "🚀 Night Shift Worker" >&2
echo "   Agent: ${AGENT_NAME}" >&2
echo "   Topic: ${TOPIC}" >&2
echo "   Repo: ${REPO_ALIAS} (${REPO_PATH})" >&2
echo "   Branch: ${BRANCH}" >&2
echo "   Type: ${TYPE}" >&2
echo "   Queue file: ${QUEUE_FILE}" >&2
echo "" >&2
echo "   ✅ Task queued for main session dispatch." >&2
echo "" >&2

# Update TASKS.md
"${SCRIPT_DIR}/lib/tasks.sh" add "${TODAY}" "${TOPIC}" "${BRANCH}" "${AGENT_NAME}" "${TYPE}" >/dev/null 2>&1 || true
"${SCRIPT_DIR}/lib/tasks.sh" update "${BRANCH}" status "queued" >/dev/null 2>&1 || true
"${SCRIPT_DIR}/lib/tasks.sh" update "${BRANCH}" result "queued" >/dev/null 2>&1 || true

# ── Output JSON ──
jq -n \
  --arg agent "$AGENT_NAME" \
  --arg topic "$TOPIC" \
  --arg repo "$REPO_ALIAS" \
  --arg branch "$BRANCH" \
  --arg type "$TYPE" \
  --arg queue_file "$QUEUE_FILE" \
  '{
    status: "queued",
    agent: $agent,
    topic: $topic,
    repo: $repo,
    branch: $branch,
    type: $type,
    queue_file: $queue_file
  }'