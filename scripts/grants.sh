#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/GRANT/CANON.md, not this file
# GRANTS: scan for upcoming deadlines
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/GRANTS.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY_EPOCH=$(date +%s)
ALERTS=()

# Extract YYYY-MM-DD dates from grant and campaign files
DATES=$(grep -rhoP '\d{4}-\d{2}-\d{2}' ${REPO_DIR}/GRANTS/*/ROADMAP.md ${REPO_DIR}/CAMPAIGNS/*.md 2>/dev/null | sort -u)

echo '{"_generated": true, "task": "GRANTS", "timestamp": "'"$NOW"'", "deadlines": [' > "$OUT.tmp"

FIRST=true
for d in $DATES; do
  D_EPOCH=$(date -d "$d" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null || continue)
  DAYS_LEFT=$(( (D_EPOCH - TODAY_EPOCH) / 86400 ))

  # Only future deadlines within 90 days
  if [ "$DAYS_LEFT" -lt 0 ] || [ "$DAYS_LEFT" -gt 90 ]; then continue; fi

  URGENCY="NOTICE"
  if [ "$DAYS_LEFT" -le 1 ]; then URGENCY="CRITICAL"
  elif [ "$DAYS_LEFT" -le 7 ]; then URGENCY="URGENT"
  elif [ "$DAYS_LEFT" -le 14 ]; then URGENCY="WARNING"
  elif [ "$DAYS_LEFT" -le 30 ]; then URGENCY="NOTICE"
  else URGENCY="INFO"; fi

  if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$OUT.tmp"; fi
  echo '  {"date": "'"$d"'", "days_left": '"$DAYS_LEFT"', "urgency": "'"$URGENCY"'"}' >> "$OUT.tmp"

  if [ "$DAYS_LEFT" -le 7 ]; then
    ALERTS+=("$d: ${URGENCY} (${DAYS_LEFT}d)")
  fi
done

echo '], "alert_count": '"${#ALERTS[@]}"'}' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"

if [ ${#ALERTS[@]} -gt 0 ]; then
  echo "ALERT: ${ALERTS[*]}"
  exit 1
fi
echo "OK: no urgent deadlines"
