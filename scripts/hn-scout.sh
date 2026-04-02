#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/CAMPAIGN/CANON.md, not this file
# HN-SCOUT: search HN Algolia for relevant threads
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/HN-SCOUT.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
AGO=$(date -u -d '24 hours ago' +%s 2>/dev/null || date -u -v-24H +%s 2>/dev/null || echo "0")
QUERIES=("healthcare+AI" "AI+governance" "clinical+AI" "prompt+engineering" "FDA+AI" "HIPAA")

THREADS="[]"
for q in "${QUERIES[@]}"; do
  sleep 1
  RESULT=$(curl -s "https://hn.algolia.com/api/v1/search?query=${q}&tags=story&numericFilters=created_at_i>${AGO},points>4&hitsPerPage=5" 2>/dev/null || echo '{"hits":[]}')
  NEW=$(echo "$RESULT" | jq -c '[.hits[]? | {title, url, points, num_comments, objectID, created_at}]' 2>/dev/null || echo '[]')
  THREADS=$(echo "$THREADS $NEW" | jq -s 'add | unique_by(.objectID)' 2>/dev/null || echo "$THREADS")
done

jq -n --argjson threads "$THREADS" --arg ts "$NOW" --arg qc "${#QUERIES[@]}" \
  '{_generated: true, task: "HN-SCOUT", timestamp: $ts, threads: $threads, query_count: ($qc | tonumber)}' > "$OUT"

THREAD_COUNT=$(jq '.threads | length' "$OUT" 2>/dev/null || echo "0")
echo "OK: $THREAD_COUNT threads found across ${#QUERIES[@]} queries"
