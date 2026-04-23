#!/usr/bin/env bash
# Night Shift — Orchestrator Entry Point
# Usage: run from cron or manually

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
REPO_DIR="/tmp/openclaw-night-shift"

# Ensure repo is up to date
cd "$REPO_DIR" || exit 1
git pull --quiet 2>/dev/null || true

# Discover and process all unprocessed missions
MISSIONS=($(ls -1 missions/*.md 2>/dev/null | grep -v '\.processed$' | grep -v 'TEMPLATE.md' | sort))

if [[ ${#MISSIONS[@]} -eq 0 ]]; then
  logger -t night-shift "No missions to process"
  exit 0
fi

logger -t night-shift "Processing ${#MISSIONS[@]} missions"

for mission in "${MISSIONS[@]}"; do
  # Skip already processed
  if [[ -f "${mission}.processed" ]]; then
    continue
  fi

  # Validate mission format
  if ! grep -q '^topic:' "$mission"; then
    logger -t night-shift "Skipping invalid mission: $(basename "$mission")"
    touch "${mission}.processed"
    continue
  fi

  # Dispatch to worker
  logger -t night-shift "Dispatching: $(basename "$mission")"
  "$REPO_DIR/lib/worker.sh" "$mission" "$REPO_DIR/config.json" \
    > "$REPO_DIR/logs/orchestrator-$(date +%Y-%m-%d).log" 2>&1

  # Mark as processed
  touch "${mission}.processed"

  # Small delay to avoid overwhelming
  sleep 2
done

# Cleanup old processed markers (>30 days)
find missions/ -name '*.md.processed' -mtime +30 -delete 2>/dev/null || true

logger -t night-shift "Done processing ${#MISSIONS[@]} missions"
