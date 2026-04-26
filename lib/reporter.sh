#!/usr/bin/env bash
set -euo pipefail

# ── reporter.sh — Generate and send morning digest email via NexLink ──
# Usage: reporter.sh <log_file> <config_file>
# All informational output goes to stderr; JSON result goes to stdout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
LOG_FILE="${1:-}"
CONFIG_FILE="${2:-${SCRIPT_DIR}/config.json}"

if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]]; then
  echo '{"error":"Missing log file"}' >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo '{"error":"Missing config.json"}' >&2
  exit 1
fi

EMAIL_TO=$(jq -r '.email.to' "$CONFIG_FILE")
NEXLINK_CLI="${HOME}/.openclaw/skills/nexlink/scripts/nexlink.py"
TODAY=$(date +%Y-%m-%d)

echo "" >&2
echo "📧 Night Shift Reporter" >&2
echo "   Log: ${LOG_FILE}" >&2
echo "   Email: ${EMAIL_TO}" >&2
echo "   NexLink: ${NEXLINK_CLI}" >&2
echo "" >&2

# Count processed missions
MISSION_COUNT=$(grep -c '→' "$LOG_FILE" 2>/dev/null || true)

# Build summary
SUMMARY=$(cat "$LOG_FILE" 2>/dev/null || echo "No log entries.")

# Build email
if [[ "$MISSION_COUNT" -gt 0 ]]; then
  EMAIL_SUBJECT="☕ Night Shift Report — ${MISSION_COUNT} missions completed"
else
  EMAIL_SUBJECT="☕ Night Shift Report — No activity"
fi

EMAIL_BODY=$(cat <<EOF
Night Shift — ${TODAY}
$(printf '%0.s=' $(seq 1 ${#TODAY}))$(printf '%0.s=' $(seq 1 10))

Missions completed: ${MISSION_COUNT}

Details:
${SUMMARY}

---
Built by Firma de AI, supported by Firma de IT
https://firmade.ai | https://firmade.it
EOF
)

echo "   Subject: ${EMAIL_SUBJECT}" >&2

# ── Send email via NexLink ──
SEND_RESULT=""
if [[ -f "$NEXLINK_CLI" ]]; then
  SEND_RESULT=$(python3 "$NEXLINK_CLI" mail send \
    --to "$EMAIL_TO" \
    --subject "$EMAIL_SUBJECT" \
    --body "$EMAIL_BODY" 2>&1) || true

  if echo "$SEND_RESULT" | grep -qi "sent\|success\|ok"; then
    echo "   ✅ Email sent successfully" >&2
  else
    echo "   ⚠️ Email send result: ${SEND_RESULT}" >&2
  fi
else
  echo "   ⚠️ NexLink CLI not found at ${NEXLINK_CLI}" >&2
fi

# ── Update TASKS.md — archive completed tasks ──
echo "   🗄️ Archiving completed tasks..." >&2
"${SCRIPT_DIR}/lib/tasks.sh" archive >/dev/null 2>&1 || true
echo "   ✅ Archive complete" >&2

# ── Output JSON ──
jq -n \
  --arg date "$TODAY" \
  --argjson missions "${MISSION_COUNT}" \
  --arg recipient "$EMAIL_TO" \
  --arg subject "$EMAIL_SUBJECT" \
  --arg send_result "$SEND_RESULT" \
  '{
    status: "ready",
    date: $date,
    missions: $missions,
    recipient: $recipient,
    subject: $subject,
    send_result: $send_result
  }'