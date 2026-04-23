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

echo ""
echo "🌙 Night Shift — ${TODAY}"
echo "   Agent: ${AGENT}"
echo "   Dry-run: ${DRY_RUN}"
echo ""

# ── Find missions ──
MISSIONS=()
for f in "${MISSIONS_DIR}"/*.md; do
  [[ -f "$f" ]] && MISSIONS+=("$f")
done

if [[ ${#MISSIONS[@]} -eq 0 ]]; then
  echo "☕ No missions found in ${MISSIONS_DIR}. Sleeping..."
  exit 0
fi

echo "📋 Found ${#MISSIONS[@]} mission(s)."

# ── Process missions ──
PROCESSED=0
for MISSION in "${MISSIONS[@]}"; do
  if [[ "$PROCESSED" -ge "$MAX_MISSIONS" ]]; then
    echo "⏭️ Max missions (${MAX_MISSIONS}) reached."
    break
  fi

  BASENAME=$(basename "$MISSION" .md)
  TOPIC=$(grep '^topic:' "$MISSION" | cut -d: -f2- | xargs 2>/dev/null || echo "$BASENAME")
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🌙 Mission: ${TOPIC}"
  echo "   File: ${BASENAME}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if $DRY_RUN; then
    echo "   ⏸️ Dry-run: Would process mission."
    echo "   📁 Research: lib/research.sh ${BASENAME}"
    echo "   🚀 Worker: lib/worker.sh ${BASENAME}"
    continue
  fi

  # ── Step 1: Research ──
  echo ""
  echo "   🔍 Step 1: Research"
  RESEARCH_RESULT=$("${SCRIPT_DIR}/lib/research.sh" "$MISSION")
  RESEARCH_TOPIC=$(echo "$RESEARCH_RESULT" | jq -r '.topic // empty')
  echo "   ✅ Research ready: ${RESEARCH_TOPIC}"

  # ── Step 2: Worker (spawn subagent) ──
  echo ""
  echo "   🚀 Step 2: Spawn Worker"
  WORKER_RESULT=$("${SCRIPT_DIR}/lib/worker.sh" "$MISSION" "$CONFIG")
  WORKER_BRANCH=$(echo "$WORKER_RESULT" | jq -r '.branch // empty')
  WORKER_STATUS=$(echo "$WORKER_RESULT" | jq -r '.status // empty')
  echo "   ✅ Worker queued: ${WORKER_STATUS}"
  echo "   🌿 Branch: ${WORKER_BRANCH}"

  # ── Step 3: Mark as processed ──
  mv "$MISSION" "${MISSION}.processed"
  PROCESSED=$((PROCESSED + 1))
  
  # Log
  echo "[${TODAY}] ${TOPIC} → ${WORKER_BRANCH}" >> "$LOG_FILE"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌅 Night Shift complete. ${PROCESSED} mission(s) processed."
echo "   Log: ${LOG_FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Step 4: Reporter (morning digest) ──
if [[ "$PROCESSED" -gt 0 ]]; then
  echo ""
  echo "   📧 Step 4: Morning Digest"
  REPORT_RESULT=$("${SCRIPT_DIR}/lib/reporter.sh" "$LOG_FILE" "$CONFIG")
  REPORT_MISSIONS=$(echo "$REPORT_RESULT" | jq -r '.missions // 0')
  REPORT_STATUS=$(echo "$REPORT_RESULT" | jq -r '.status // empty')
  echo "   ✅ Digest ready: ${REPORT_STATUS} (${REPORT_MISSIONS} missions)"
  echo "   📬 Email will be sent to: ${EMAIL_TO}"
fi

echo ""
echo "☕ Done. See you tomorrow night."
echo ""
