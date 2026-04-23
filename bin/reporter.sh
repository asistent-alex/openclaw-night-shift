#!/usr/bin/env bash
# Night Shift — Daily Status Reporter
# Sends email digest of completed missions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
TASKS_MD="${SCRIPT_DIR}/TASKS.md"
LOGS_DIR="${SCRIPT_DIR}/logs"

if [[ ! -f "$TASKS_MD" ]]; then
  logger -t night-shift-reporter "TASKS.md not found"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

# Count completed missions from yesterday
COMPLETED=$(grep -c "^### \[${YESTERDAY}\]" "$TASKS_MD" 2>/dev/null || echo "0")
TOTAL=$(grep -c "^### \[" "$TASKS_MD" 2>/dev/null || echo "0")

# Extract yesterday's missions
MISSIONS=$(grep -A 20 "^### \[${YESTERDAY}\]" "$TASKS_MD" 2>/dev/null | head -80)

# Build email subject
if [[ "$COMPLETED" -gt 0 ]]; then
  SUBJECT="☕ Night Shift Report — ${COMPLETED} missions completed"
else
  SUBJECT="☕ Night Shift Report — No activity"
fi

# Build email body
BODY=$(cat <<EOF
# Night Shift Daily Report

**Date:** ${TODAY}  
**Period:** ${YESTERDAY} 2:00 AM → ${TODAY} 2:00 AM (Europe/Bucharest)

## Summary

| Metric | Value |
|--------|-------|
| Missions completed | ${COMPLETED} |
| Total in history | ${TOTAL} |

## Completed Missions

${MISSIONS}

---

*Built by Firma de AI, supported by Firma de IT*  
<https://firmade.ai> | <https://firmade.it>
EOF
)

# Send email via NexLink
# Using the nexlink skill's email capability
if command -v python3 &>/dev/null; then
  python3 <<PYEOF >/dev/null 2>&1
import sys
sys.path.insert(0, "${HOME}/.openclaw/skills/nexlink")
from nexlink.exchange import ExchangeClient

client = ExchangeClient()
client.connect()

msg = {
    "to": "alex.bogdan@firmade.it",
    "subject": "${SUBJECT}",
    "body": """${BODY}""",
    "is_html": False
}

client.send_email(**msg)
print(f"Email sent: {msg['subject']}")
PYEOF
else
  logger -t night-shift-reporter "python3 not available, skipping email"
fi

logger -t night-shift-reporter "Report sent: ${COMPLETED} missions completed"
