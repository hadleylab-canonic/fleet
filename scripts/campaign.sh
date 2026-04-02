#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/CAMPAIGN/CANON.md, not this file
# CAMPAIGN: poll emission engagement on HN (Firebase API)
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/CAMPAIGN.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Extract HN post IDs from campaign files
HN_IDS=$(grep -rhoP '(?:posted_id|hn_id|objectID)[:\s]+(\d+)' "${REPO_DIR}/CAMPAIGNS/" 2>/dev/null | grep -oP '\d+' | sort -u | head -20 || true)

EMISSIONS="[]"
for id in $HN_IDS; do
  sleep 1
  RESULT=$(curl -s "https://hacker-news.firebaseio.com/v0/item/${id}.json" 2>/dev/null || echo '{}')
  ENTRY=$(echo "$RESULT" | jq -c '{id: .id, title: .title, score: .score, comments: .descendants}' 2>/dev/null || echo '{}')
  EMISSIONS=$(echo "$EMISSIONS" | jq --argjson e "$ENTRY" '. + [$e]' 2>/dev/null || echo "$EMISSIONS")
done

POLLED=$(echo $HN_IDS | wc -w | tr -d ' ')
jq -n --argjson emissions "$EMISSIONS" --arg ts "$NOW" --arg pc "${POLLED:-0}" \
  '{_generated: true, task: "CAMPAIGN", timestamp: $ts, emissions: $emissions, polled_count: ($pc | tonumber)}' > "$OUT"

echo "OK: polled ${POLLED:-0} HN emissions"
