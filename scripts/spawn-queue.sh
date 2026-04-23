#!/usr/bin/env bash
set -euo pipefail

# ── spawn-queue.sh — Read task files and output spawn commands ──
# Usage: ./scripts/spawn-queue.sh [--exec]
#   --exec: Actually run the spawn commands (requires openclaw CLI)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
LOGS_DIR="${SCRIPT_DIR}/logs"
EXEC=false

# ── Parse args ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --exec) EXEC=true; shift ;;
    *) echo "Usage: $0 [--exec]"; exit 1 ;;
  esac
done

# ── Find task files ──
TASKS=()
for f in "${LOGS_DIR}"/task-*.md; do
  [[ -f "$f" ]] || continue
  # Skip already processed (check for status: done/failed/queued)
  if grep -q "^## Status: \(done\|failed\)" "$f" 2>/dev/null; then
    continue
  fi
  TASKS+=("$f")
done

if [[ ${#TASKS[@]} -eq 0 ]]; then
  echo "☕ No pending tasks in ${LOGS_DIR}."
  exit 0
fi

echo ""
echo "🚀 Night Shift — Spawn Queue"
echo "   Found ${#TASKS[@]} pending task(s)."
echo ""

for TASK_FILE in "${TASKS[@]}"; do
  BASENAME=$(basename "$TASK_FILE" .md)
  AGENT=$(grep "^## Agent:" "$TASK_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "dev-nexlink")
  TOPIC=$(grep "^## Mission:" "$TASK_FILE" 2>/dev/null | cut -d: -f2- | xargs || echo "$BASENAME")
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Task: ${TOPIC}"
  echo "   File: ${TASK_FILE}"
  echo "   Agent: ${AGENT}"
  echo ""
  
  if $EXEC; then
    echo "   🚀 Spawning subagent..."
    # NOTE: This requires openclaw CLI or API access.
    # For now, we output the command that should be run.
    echo "   (Not implemented — run the command below manually)"
  fi
  
  echo ""
  echo "   Command for OpenClaw assistant:"
  echo "   ────────────────────────────────────────"
  echo "   sessions_spawn --runtime subagent --mode run \\"
  echo "     --agent ${AGENT} \\"
  echo "     --task 'Execute the mission in ${TASK_FILE}'"
  echo "   ────────────────────────────────────────"
  echo ""
done

echo ""
echo "☕ Done. Copy the commands above and run them in OpenClaw."
echo ""
