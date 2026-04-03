#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/GRANT/CANON.md, not this file
# GRANTS: scan for upcoming deadlines with context
set -uo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/GRANTS.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY_EPOCH=$(date +%s)

# Extract dates WITH surrounding context (the line containing the date)
DEADLINES="[]"
ALERT_COUNT=0

# Scan campaign files for event dates with names
for f in "${REPO_DIR}"/CAMPAIGNS/*.md; do
  [ -f "$f" ] || continue
  NAME=$(basename "$f" .md)
  # Get dates: frontmatter field
  DATE=$(grep -m1 '^dates:' "$f" 2>/dev/null | grep -oP '\d{4}-\d{2}-\d{2}' | head -1 || true)
  [ -z "$DATE" ] && continue
  EVENT=$(grep -m1 '^event:' "$f" 2>/dev/null | sed 's/^event:\s*//' || echo "$NAME")
  D_EPOCH=$(date -d "$DATE" +%s 2>/dev/null) || continue
  DAYS_LEFT=$(( (D_EPOCH - TODAY_EPOCH) / 86400 ))
  [ "$DAYS_LEFT" -lt -7 ] || [ "$DAYS_LEFT" -gt 90 ] && continue
  URGENCY="INFO"
  [ "$DAYS_LEFT" -le 1 ] && URGENCY="CRITICAL"
  [ "$DAYS_LEFT" -gt 1 ] && [ "$DAYS_LEFT" -le 7 ] && URGENCY="URGENT"
  [ "$DAYS_LEFT" -gt 7 ] && [ "$DAYS_LEFT" -le 14 ] && URGENCY="WARNING"
  [ "$DAYS_LEFT" -gt 14 ] && [ "$DAYS_LEFT" -le 30 ] && URGENCY="NOTICE"
  [ "$DAYS_LEFT" -le 7 ] && [ "$DAYS_LEFT" -ge 0 ] && ALERT_COUNT=$((ALERT_COUNT + 1))
  DEADLINES=$(echo "$DEADLINES" | jq --arg d "$DATE" --arg dl "$DAYS_LEFT" --arg u "$URGENCY" \
    --arg n "$EVENT" --arg s "CAMPAIGNS/$NAME.md" \
    '. + [{date: $d, days_left: ($dl | tonumber), urgency: $u, name: $n, source: $s}]')
done

# Scan grant ROADMAPs for checkbox items with dates
for f in "${REPO_DIR}"/GRANTS/*/ROADMAP.md; do
  [ -f "$f" ] || continue
  GRANT=$(basename "$(dirname "$f")")
  grep -P '\d{4}-\d{2}-\d{2}' "$f" 2>/dev/null | while IFS= read -r line; do
    DATE=$(echo "$line" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
    [ -z "$DATE" ] && continue
    LABEL=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*\[.\][[:space:]]*//' | sed 's/[[:space:]]*([0-9-]*)$//' | head -c 80)
    D_EPOCH=$(date -d "$DATE" +%s 2>/dev/null) || continue
    DAYS_LEFT=$(( (D_EPOCH - TODAY_EPOCH) / 86400 ))
    [ "$DAYS_LEFT" -lt -7 ] || [ "$DAYS_LEFT" -gt 90 ] && continue
    URGENCY="INFO"
    [ "$DAYS_LEFT" -le 1 ] && URGENCY="CRITICAL"
    [ "$DAYS_LEFT" -gt 1 ] && [ "$DAYS_LEFT" -le 7 ] && URGENCY="URGENT"
    [ "$DAYS_LEFT" -gt 7 ] && [ "$DAYS_LEFT" -le 14 ] && URGENCY="WARNING"
    [ "$DAYS_LEFT" -gt 14 ] && [ "$DAYS_LEFT" -le 30 ] && URGENCY="NOTICE"
    [ "$DAYS_LEFT" -le 7 ] && [ "$DAYS_LEFT" -ge 0 ] && ALERT_COUNT=$((ALERT_COUNT + 1))
    DEADLINES=$(echo "$DEADLINES" | jq --arg d "$DATE" --arg dl "$DAYS_LEFT" --arg u "$URGENCY" \
      --arg n "$LABEL" --arg s "GRANTS/$GRANT/ROADMAP.md" \
      '. + [{date: $d, days_left: ($dl | tonumber), urgency: $u, name: $n, source: $s}]')
  done
done

# Sort by days_left
DEADLINES=$(echo "$DEADLINES" | jq 'sort_by(.days_left)')

jq -n --argjson deadlines "$DEADLINES" --arg ts "$NOW" --argjson ac "$ALERT_COUNT" \
  '{_generated: true, task: "GRANTS", timestamp: $ts, deadlines: $deadlines, alert_count: $ac}' > "$OUT"

if [ "$ALERT_COUNT" -gt 0 ]; then
  URGENT=$(echo "$DEADLINES" | jq -r '[.[] | select(.days_left <= 7 and .days_left >= 0)] | .[] | "\(.name) (\(.days_left)d)"' | head -3 | tr '\n' ', ' | sed 's/,$//')
  echo "ALERT: $URGENT"
  exit 1
fi
echo "OK: no urgent deadlines"
