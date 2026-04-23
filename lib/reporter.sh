#!/usr/bin/env bash
set -euo pipefail

# ── reporter.sh — Generate and send morning digest email ──
# Usage: reporter.sh <log_file> <config_file>

LOG_FILE="${1:-}"
CONFIG_FILE="${2:-./config.json}"

if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]]; then
  echo "❌ Missing log file" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing config.json" >&2
  exit 1
fi

EMAIL_TO=$(jq -r '.email.to' "$CONFIG_FILE")
TODAY=$(date +%Y-%m-%d)

echo ""
echo "📧 Night Shift Reporter"
echo "   Log: ${LOG_FILE}"
echo "   Email: ${EMAIL_TO}"
echo ""

# Count processed missions
MISSION_COUNT=$(grep -c '→' "$LOG_FILE" 2>/dev/null || echo "0")

# Build summary
SUMMARY=$(cat "$LOG_FILE" 2>/dev/null || echo "No log entries.")

# Build email body
EMAIL_SUBJECT="Night Shift Digest — ${TODAY} (${MISSION_COUNT} missions)"
EMAIL_BODY=$(cat <<EOF
Night Shift Report — ${TODAY}
================================

Missions completed: ${MISSION_COUNT}

Details:
${SUMMARY}

---
Built by Firma de AI, supported by Firma de IT
https://firmade.ai | https://firmade.it
EOF
)

echo "📬 Email prepared:"
echo "   To: ${EMAIL_TO}"
echo "   Subject: ${EMAIL_SUBJECT}"
echo ""
echo "   (In the full implementation, this would send via nexlink skill)"
echo "   Example: openclaw nexlink send --to ${EMAIL_TO} --subject '${EMAIL_SUBJECT}'"

# ── Placeholder output ──
cat <<EOF
{
  "status": "ready",
  "date": "${TODAY}",
  "missions": ${MISSION_COUNT},
  "recipient": "${EMAIL_TO}",
  "subject": "${EMAIL_SUBJECT}",
  "body_length": ${#EMAIL_BODY}
}
EOF
