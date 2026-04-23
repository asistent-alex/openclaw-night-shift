#!/usr/bin/env bash
set -euo pipefail

# ── reporter.sh — Generate and send morning digest email ──
# Usage: reporter.sh <log_file> <config_file>
# All informational output goes to stderr; JSON result goes to stdout

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

echo "" >&2
echo "📧 Night Shift Reporter" >&2
echo "   Log: ${LOG_FILE}" >&2
echo "   Email: ${EMAIL_TO}" >&2
echo "" >&2

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

echo "📬 Email prepared:" >&2
echo "   To: ${EMAIL_TO}" >&2
echo "   Subject: ${EMAIL_SUBJECT}" >&2
echo "" >&2
echo "   (In the full implementation, this would send via nexlink skill)" >&2
echo "   Example: openclaw nexlink send --to ${EMAIL_TO} --subject '${EMAIL_SUBJECT}'" >&2

# ── Output JSON safely using jq ──
jq -n \
  --arg date "$TODAY" \
  --argjson missions "${MISSION_COUNT}" \
  --arg recipient "$EMAIL_TO" \
  --arg subject "$EMAIL_SUBJECT" \
  --argjson body_length "${#EMAIL_BODY}" \
  '{
    status: "ready",
    date: $date,
    missions: $missions,
    recipient: $recipient,
    subject: $subject,
    body_length: $body_length
  }'
