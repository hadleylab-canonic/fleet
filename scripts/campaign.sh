#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/CAMPAIGN/CANON.md, not this file
# CAMPAIGN: poll emission engagement on HN (Firebase API)
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/CAMPAIGN.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Extract HN post IDs from campaign files (posted_id: or hn_id: fields)
HN_IDS=$(grep -rhoP '(?:posted_id|hn_id|objectID)[:\s]+(\d+)' ${REPO_DIR}/CAMPAIGNS/ 2>/dev/null | grep -oP '\d+' | sort -u | head -20)

echo '{"_generated": true, "task": "CAMPAIGN", "timestamp": "'"$NOW"'", "emissions": [' > "$OUT.tmp"

FIRST=true
for id in $HN_IDS; do
  sleep 1
  RESULT=$(curl -s "https://hacker-news.firebaseio.com/v0/item/${id}.json" 2>/dev/null)
  TITLE=$(echo "$RESULT" | jq -r '.title // "unknown"' 2>/dev/null || echo "unknown")
  SCORE=$(echo "$RESULT" | jq -r '.score // 0' 2>/dev/null || echo "0")
  COMMENTS=$(echo "$RESULT" | jq -r '.descendants // 0' 2>/dev/null || echo "0")

  if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$OUT.tmp"; fi
  echo '  {"id": '"$id"', "title": "'"$TITLE"'", "score": '"$SCORE"', "comments": '"$COMMENTS"'}' >> "$OUT.tmp"
done

echo '], "polled_count": '"$(echo $HN_IDS | wc -w)"'}' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"

echo "OK: polled $(echo $HN_IDS | wc -w) HN emissions"
