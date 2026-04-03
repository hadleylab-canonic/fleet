#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/CITATION/CANON.md, not this file
# CITATIONS: validate bibliography URLs with reference codes
set -uo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/CITATIONS.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BIBO="${REPO_DIR}/SERVICES/CITATION/BIBLIOGRAPHY.md"

if [ ! -f "$BIBO" ]; then
  jq -n --arg ts "$NOW" '{_generated: true, task: "CITATIONS", timestamp: $ts, error: "BIBLIOGRAPHY.md not found"}' > "$OUT"
  echo "SKIP: $BIBO not found"; exit 0
fi

# Extract URL with its reference code (line context)
# Bibliography format: | X-6 | Source name | https://url |
BROKEN="[]"
HEALTHY=0
TOTAL=0

while IFS= read -r line; do
  URL=$(echo "$line" | grep -oP 'https?://[^\s\)\]>"|]+' | head -1)
  [ -z "$URL" ] && continue
  # Extract reference code from same line (e.g., X-6, I-1, G-3)
  REF=$(echo "$line" | grep -oP '^[|]\s*([A-Z]-\d+)' | sed 's/[| ]//g' || true)
  # Extract source name (second column)
  NAME=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' 2>/dev/null | head -c 60 || true)

  TOTAL=$((TOTAL + 1))
  STATUS=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 15 "$URL" 2>/dev/null || echo "000")
  sleep 1

  if [ "$STATUS" -lt 200 ] || [ "$STATUS" -ge 400 ]; then
    BROKEN=$(echo "$BROKEN" | jq --arg u "$URL" --arg s "$STATUS" --arg r "${REF:-?}" --arg n "${NAME:-?}" \
      '. + [{url: $u, status: ($s | tonumber), ref: $r, name: $n}]')
  else
    HEALTHY=$((HEALTHY + 1))
  fi
done < <(grep -P 'https?://' "$BIBO" 2>/dev/null | head -200)

BROKEN_COUNT=$(echo "$BROKEN" | jq 'length')
jq -n --argjson broken "$BROKEN" --arg ts "$NOW" --argjson total "$TOTAL" \
  --argjson bc "$BROKEN_COUNT" --argjson hc "$HEALTHY" \
  '{_generated: true, task: "CITATIONS", timestamp: $ts, total_checked: $total, healthy: $hc, broken_count: $bc, alert_count: $bc, broken: $broken}' > "$OUT"

if [ "$BROKEN_COUNT" -gt 0 ]; then
  echo "ALERT: $BROKEN_COUNT broken citations of $TOTAL checked"
  exit 1
fi
echo "OK: $TOTAL citation URLs healthy"
