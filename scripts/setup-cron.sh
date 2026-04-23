#!/usr/bin/env bash
set -euo pipefail

# ── setup-cron.sh — Install night-shift cron job ──
# Usage: ./scripts/setup-cron.sh [--remove]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG="${SCRIPT_DIR}/config.json"
CRON_COMMENT="# openclaw-night-shift"
REMOVE=false

# ── Parse args ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove) REMOVE=true; shift ;;
    *) echo "Usage: $0 [--remove]"; exit 1 ;;
  esac
done

# ── Validate ──
if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Missing config.json at ${CONFIG}"
  exit 1
fi

SCHEDULE=$(jq -r '.schedule // "0 22 * * *"' "$CONFIG")
NIGHT_SHIFT="${SCRIPT_DIR}/night-shift.sh"
LOG="${SCRIPT_DIR}/logs/cron.log"
mkdir -p "$(dirname "$LOG")"

# Build cron line
CRON_LINE="${SCHEDULE} cd ${SCRIPT_DIR} && ${NIGHT_SHIFT} >> ${LOG} 2>&1 ${CRON_COMMENT}"

echo ""
echo "🌙 Night Shift — Cron Setup"
echo "   Schedule: ${SCHEDULE}"
echo "   Command:  ${NIGHT_SHIFT}"
echo "   Log:      ${LOG}"
echo ""

if $REMOVE; then
  echo "🗑️ Removing cron job..."
  (crontab -l 2>/dev/null | grep -v "${CRON_COMMENT}" || true) | crontab -
  echo "✅ Cron job removed."
  exit 0
fi

# Check if already exists
if crontab -l 2>/dev/null | grep -q "${CRON_COMMENT}"; then
  echo "⚠️ Cron job already exists. Updating..."
  (crontab -l 2>/dev/null | grep -v "${CRON_COMMENT}" || true; echo "${CRON_LINE}") | crontab -
else
  echo "➕ Adding cron job..."
  (crontab -l 2>/dev/null || true; echo "${CRON_LINE}") | crontab -
fi

echo "✅ Cron job installed."
echo ""
echo "   Current crontab:"
crontab -l | grep "${CRON_COMMENT}" || echo "   (not found)"
echo ""
echo "   Test run now:"
echo "   cd ${SCRIPT_DIR} && ./night-shift.sh --dry-run"
