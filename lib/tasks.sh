#!/usr/bin/env bash
set -euo pipefail

# ── tasks.sh — Manage TASKS.md tracking file ──
# All informational output goes to stderr; JSON result goes to stdout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
TASKS_FILE="${SCRIPT_DIR}/TASKS.md"

# Ensure TASKS.md exists with proper structure
init_tasks() {
  if [[ ! -f "$TASKS_FILE" ]]; then
    cat > "$TASKS_FILE" <<'EOF'
# Night Shift Tasks — Tracker

## Active

## History
EOF
  fi
}

# Add a new task to "Active" section
# Usage: add_task <date> <topic> <branch> <agent> <type>
add_task() {
  local DATE="${1:-}"
  local TOPIC="${2:-}"
  local BRANCH="${3:-}"
  local AGENT="${4:-}"
  local TYPE="${5:-feature}"

  init_tasks

  # Build new entry
  local ENTRY
  ENTRY=$(cat <<EOF

### [${DATE}] ${TOPIC}
- **Status:** running
- **Branch:** ${BRANCH}
- **Agent:** ${AGENT}
- **Type:** ${TYPE}
- **PR:** -
- **Result:** -
- **Tokens:** ~-
EOF
)

  # Read file content
  local CONTENT
  CONTENT=$(cat "$TASKS_FILE")

  # Find line numbers for sections
  local ACTIVE_LINE
  ACTIVE_LINE=$(echo "$CONTENT" | grep -n "^## Active" | head -1 | cut -d: -f1)

  if [[ -z "$ACTIVE_LINE" ]]; then
    # No Active section found, append
    echo "$CONTENT" > "$TASKS_FILE"
    echo "" >> "$TASKS_FILE"
    echo "## Active" >> "$TASKS_FILE"
    echo "$ENTRY" >> "$TASKS_FILE"
    return
  fi

  # Extract header (everything before ## Active)
  local HEADER
  HEADER=$(echo "$CONTENT" | head -n $((ACTIVE_LINE - 1)))

  # Extract everything after ## Active
  local AFTER_ACTIVE
  AFTER_ACTIVE=$(echo "$CONTENT" | tail -n +$((ACTIVE_LINE + 1)))

  # Find History section in AFTER_ACTIVE
  local HISTORY_LINE
  HISTORY_LINE=$(echo "$AFTER_ACTIVE" | grep -n "^## History" | head -1 | cut -d: -f1)

  local ACTIVE_CONTENT
  local HISTORY_CONTENT
  if [[ -n "$HISTORY_LINE" && "$HISTORY_LINE" -gt 0 ]]; then
    ACTIVE_CONTENT=$(echo "$AFTER_ACTIVE" | head -n $((HISTORY_LINE - 1)))
    HISTORY_CONTENT=$(echo "$AFTER_ACTIVE" | tail -n +"$HISTORY_LINE")
  else
    ACTIVE_CONTENT="$AFTER_ACTIVE"
    HISTORY_CONTENT="## History"
  fi

  # Rebuild file preserving header
  cat > "$TASKS_FILE" <<EOF
${HEADER}
## Active
${ENTRY}
${ACTIVE_CONTENT}

${HISTORY_CONTENT}
EOF

  echo "   📝 Task added to TASKS.md" >&2

  jq -n \
    --arg date "$DATE" \
    --arg topic "$TOPIC" \
    --arg branch "$BRANCH" \
    --arg status "running" \
    '{status: $status, date: $date, topic: $topic, branch: $branch}'
}

# Update task status/result/PR in Active section
# Usage: update_task <branch> <field> <value>
update_task() {
  local BRANCH="${1:-}"
  local FIELD="${2:-status}"
  local VALUE="${3:-}"

  init_tasks

  # Capitalize field for markdown matching (status → Status)
  local FIELD_CAP
  FIELD_CAP=$(echo "$FIELD" | sed 's/^./\u&/')

  # Use awk to find the task with matching branch and update the field
  # Buffer each task entry, then check if it contains the target branch
  local TEMP_FILE
  TEMP_FILE=$(mktemp)

  awk -v branch="$BRANCH" -v field="$FIELD_CAP" -v value="$VALUE" '
    BEGIN {
      in_active = 0
      in_history = 0
      task_buffer = ""
      output_buffer = ""
      header_buffer = ""
      header_done = 0
      updated = 0
    }
    /^# / {
      if (!header_done) {
        header_buffer = header_buffer $0 "\n"
        next
      }
    }
    /^## Active/  { in_active = 1; in_history = 0; header_done = 1; next }
    /^## History/ {
      # Flush any pending task before switching to history
      if (task_buffer != "") {
        if (index(task_buffer, "**Branch:** " branch) > 0 && !updated) {
          # Update field in this task
          new_task = ""
          split(task_buffer, lines, "\n")
          for (i = 1; i <= length(lines); i++) {
            if (lines[i] ~ "^- \\*\\*" field ":") {
              new_task = new_task "- **" field ":** " value "\n"
              updated = 1
            } else {
              new_task = new_task lines[i] "\n"
            }
          }
          task_buffer = new_task
        }
        output_buffer = output_buffer task_buffer "\n\n"
        task_buffer = ""
      }
      in_active = 0
      in_history = 1
      next
    }

    in_active {
      if ($0 ~ /^### \[/) {
        # Start of new task - flush previous
        if (task_buffer != "") {
          if (index(task_buffer, "**Branch:** " branch) > 0 && !updated) {
            new_task = ""
            split(task_buffer, lines, "\n")
            for (i = 1; i <= length(lines); i++) {
              if (lines[i] ~ "^- \\*\\*" field ":") {
                new_task = new_task "- **" field ":** " value "\n"
                updated = 1
              } else {
                new_task = new_task lines[i] "\n"
              }
            }
            task_buffer = new_task
          }
          output_buffer = output_buffer task_buffer "\n\n"
        }
        task_buffer = $0 "\n"
        next
      }
      if (task_buffer != "") {
        task_buffer = task_buffer $0 "\n"
      } else {
        output_buffer = output_buffer $0 "\n"
      }
      next
    }

    in_history {
      output_buffer = output_buffer $0 "\n"
      next
    }

    END {
      # Flush last task buffer
      if (task_buffer != "") {
        if (index(task_buffer, "**Branch:** " branch) > 0 && !updated) {
          new_task = ""
          split(task_buffer, lines, "\n")
          for (i = 1; i <= length(lines); i++) {
            if (lines[i] ~ "^- \\*\\*" field ":") {
              new_task = new_task "- **" field ":** " value "\n"
              updated = 1
            } else {
              new_task = new_task lines[i] "\n"
            }
          }
          task_buffer = new_task
        }
        output_buffer = output_buffer task_buffer "\n\n"
      }

      # Print header
      if (header_buffer != "") {
        printf "%s", header_buffer
      }

      # Print Active section
      print "## Active"
      if (output_buffer != "") {
        print ""
        printf "%s", output_buffer
      }

      # Print History section
      print "## History"
    }
  ' "$TASKS_FILE" > "$TEMP_FILE"

  mv "$TEMP_FILE" "$TASKS_FILE"

  echo "   📝 Task updated: ${BRANCH} → ${FIELD}=${VALUE}" >&2

  jq -n \
    --arg branch "$BRANCH" \
    --arg field "$FIELD" \
    --arg value "$VALUE" \
    '{status: "updated", branch: $branch, field: $field, value: $value}'
}

# Archive all "done" or "failed" tasks from Active to History
# Usage: archive_tasks
archive_tasks() {
  init_tasks

  local TEMP_FILE
  TEMP_FILE=$(mktemp)

  awk '
    BEGIN {
      in_active = 0
      in_history = 0
      task_buffer = ""
      keep_buffer = ""
      archive_buffer = ""
      header_buffer = ""
      header_done = 0
    }
    /^# / {
      if (!header_done) {
        header_buffer = header_buffer $0 "\n"
        next
      }
    }
    /^## Active/  { in_active = 1; in_history = 0; header_done = 1; next }
    /^## History/ { in_active = 0; in_history = 1; header_done = 1; next }

    in_active && !header_done { header_done = 1 }

    in_active {
      if ($0 ~ /^$/) {
        if (task_buffer != "") {
          if (task_buffer ~ /\*\*Status:\*\* (done|failed|aborted)/) {
            archive_buffer = archive_buffer task_buffer "\n\n"
          } else {
            keep_buffer = keep_buffer task_buffer "\n\n"
          }
          task_buffer = ""
        }
        next
      }
      if ($0 ~ /^### \[/) {
        if (task_buffer != "") {
          if (task_buffer ~ /\*\*Status:\*\* (done|failed|aborted)/) {
            archive_buffer = archive_buffer task_buffer "\n\n"
          } else {
            keep_buffer = keep_buffer task_buffer "\n\n"
          }
        }
        task_buffer = $0 "\n"
        next
      }
      if (task_buffer != "") {
        task_buffer = task_buffer $0 "\n"
      } else {
        keep_buffer = keep_buffer $0 "\n"
      }
      next
    }

    in_history {
      archive_buffer = archive_buffer $0 "\n"
      next
    }

    !header_done {
      header_buffer = header_buffer $0 "\n"
      next
    }

    END {
      if (task_buffer != "") {
        if (task_buffer ~ /\*\*Status:\*\* (done|failed|aborted)/) {
          archive_buffer = archive_buffer task_buffer "\n\n"
        } else {
          keep_buffer = keep_buffer task_buffer "\n\n"
        }
      }

      # Print header
      if (header_buffer != "") {
        printf "%s", header_buffer
      }

      # Print Active section
      print "## Active"
      if (keep_buffer != "") {
        print ""
        printf "%s", keep_buffer
      }

      # Print History section
      print "## History"
      if (archive_buffer != "") {
        print ""
        printf "%s", archive_buffer
      }
    }
  ' "$TASKS_FILE" > "$TEMP_FILE"

  mv "$TEMP_FILE" "$TASKS_FILE"

  echo "   🗄️ Archived completed tasks to History" >&2

  jq -n '{status: "archived"}'
}

# ── Main CLI ──
COMMAND="${1:-}"
shift || true

case "$COMMAND" in
  add)    add_task "$@" ;;
  update) update_task "$@" ;;
  archive) archive_tasks ;;
  *)
    echo "Usage: tasks.sh {add|update|archive} [args...]" >&2
    exit 1
    ;;
esac
