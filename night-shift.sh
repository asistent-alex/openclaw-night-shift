#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/config.json"
MISSIONS_DIR="${SCRIPT_DIR}/missions"
LOGS_DIR="${SCRIPT_DIR}/logs"
DRY_RUN=false

# ── Parse args ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Usage: $0 [--dry-run]"; exit 1 ;;
  esac
done

# ── Validate ──
if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Missing config.json. Copy from config.example.json and edit."
  exit 1
fi

AGENT=$(jq -r '.agent' "$CONFIG")
EMAIL_TO=$(jq -r '.email.to' "$CONFIG")
BRANCH_PREFIX=$(jq -r '.branch_prefix' "$CONFIG")
MAX_MISSIONS=$(jq -r '.max_missions_per_night' "$CONFIG")

TODAY=$(date +%Y-%m-%d)
LOG_FILE="${LOGS_DIR}/${TODAY}.log"
mkdir -p "$LOGS_DIR"

# ── Find missions ──
MISSIONS=()
for f in "${MISSIONS_DIR}"/*.md; do
  [[ -f "$f" ]] && MISSIONS+=("$f")
done

if [[ ${#MISSIONS[@]} -eq 0 ]]; then
  echo "☕ No missions found in ${MISSIONS_DIR}. Sleeping..."
  exit 0
fi

# ── Process missions ──
PROCESSED=0
for MISSION in "${MISSIONS[@]}"; do
  if [[ "$PROCESSED" -ge "$MAX_MISSIONS" ]]; then
    echo "⏭️ Max missions (${MAX_MISSIONS}) reached."
    break
  fi

  BASENAME=$(basename "$MISSION" .md)
  TOPIC=$(grep '^topic:' "$MISSION" | cut -d: -f2- | xargs || echo "$BASENAME")
  REPO=$(grep '^repo:' "$MISSION" | cut -d: -f2- | xargs || echo "nexlink")
  
  BRANCH="${BRANCH_PREFIX}/${TODAY}-${BASENAME}"

  echo ""
  echo "🌙 Night Shift — Mission: ${TOPIC}"
  echo "   Branch: ${BRANCH}"
  echo "   Repo: ${REPO}"
  echo "   Dry-run: ${DRY_RUN}"

  if $DRY_RUN; then
    echo "   ⏸️ Would spawn subagent '${AGENT}' and run prompt-to-pr feature."
    continue
  fi

  # ── Step 1: Spawn subagent for research + implementation ──
  echo "   🚀 Spawning subagent '${AGENT}'..."
  
  # Build prompt from mission file
  MISSION_CONTENT=$(cat "$MISSION")
  
  # The subagent will:
  # 1. Research the topic via web search
  # 2. Use prompt-to-pr to implement
  # 3. Create branch and open PR
  
  # For now: log and mark as processed
  echo "   ✅ Mission queued for subagent."
  echo "   📝 Results will be in ${BRANCH}"

  # Mark as processed (rename or move)
  mv "$MISSION" "${MISSION}.processed"
  PROCESSED=$((PROCESSED + 1))
  
  # Log
  echo "[${TODAY}] ${TOPIC} → ${BRANCH}" >> "$LOG_FILE"
done

echo ""
echo "🌅 Night Shift complete. ${PROCESSED} missions processed."
echo "   Log: ${LOG_FILE}"

if [[ "$PROCESSED" -gt 0 ]]; then
  echo "   📧 Morning digest will be sent to ${EMAIL_TO}"
fi
