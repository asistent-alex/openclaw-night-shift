#!/usr/bin/env bash
set -euo pipefail

# ── research.sh — Web search + synthesis for a mission ──
# Usage: research.sh <mission_file>
# Output: JSON with {topic, sources, summary}

MISSION_FILE="${1:-}"
if [[ -z "$MISSION_FILE" || ! -f "$MISSION_FILE" ]]; then
  echo '{"error":"Missing or invalid mission file"}' >&2
  exit 1
fi

# Extract fields from frontmatter + body
TOPIC=$(grep '^topic:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | head -1)
REPO=$(grep '^repo:' "$MISSION_FILE" 2>/dev/null | cut -d: -f2- | sed 's/^ *//' | head -1 || echo "nexlink")

if [[ -z "$TOPIC" ]]; then
  TOPIC=$(basename "$MISSION_FILE" .md)
fi

# Build search query from topic + research questions
RESEARCH_QS=$(sed -n '/^## Research Questions/,/^## /p' "$MISSION_FILE" | sed '1d;$d' | grep '^[0-9]' | sed 's/^[0-9.]* *//' | tr '\n' ' ')

QUERY="${TOPIC} ${RESEARCH_QS}"
QUERY="${QUERY:0:200}"  # trim for safety

echo "🔍 Researching: ${TOPIC}" >&2

# ── Web search (placeholder — will be replaced by actual OpenClaw tool call) ──
# In the actual implementation, the worker subagent will run web_search tool.
# This script prepares the research prompt.

cat <<EOF
{
  "topic": "${TOPIC}",
  "repo": "${REPO}",
  "query": "${QUERY}",
  "mission_file": "${MISSION_FILE}",
  "research_prompt": "Research the following topic and provide a concise summary with 3-5 key findings, plus 2-3 actionable implementation suggestions. Topic: ${TOPIC}. Research questions: ${RESEARCH_QS}"
}
EOF
