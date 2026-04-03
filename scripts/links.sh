#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/BLOG/CANON.md, not this file
# LINKS: validate external URLs in blog Sources tables, with source file context
set -uo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/LINKS.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Extract URLs with source file context
BROKEN="[]"
HEALTHY=0
TOTAL=0

for f in "${REPO_DIR}"/BLOGS/*.md; do
  [ -f "$f" ] || continue
  BLOG=$(basename "$f" .md)
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    TOTAL=$((TOTAL + 1))
    STATUS=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 15 "$url" 2>/dev/null || echo "000")
    sleep 1
    if [ "$STATUS" -lt 200 ] || [ "$STATUS" -ge 400 ]; then
      BROKEN=$(echo "$BROKEN" | jq --arg u "$url" --arg s "$STATUS" --arg b "$BLOG" \
        '. + [{url: $u, status: ($s | tonumber), source: $b}]')
    else
      HEALTHY=$((HEALTHY + 1))
    fi
  done < <(grep -oP 'https?://[^\s\)\]>"]+' "$f" 2>/dev/null | sort -u)
  # Cap at 100 URLs total
  [ "$TOTAL" -ge 100 ] && break
done

BROKEN_COUNT=$(echo "$BROKEN" | jq 'length')
jq -n --argjson broken "$BROKEN" --arg ts "$NOW" --argjson total "$TOTAL" \
  --argjson bc "$BROKEN_COUNT" --argjson hc "$HEALTHY" \
  '{_generated: true, task: "LINKS", timestamp: $ts, total_checked: $total, healthy: $hc, broken_count: $bc, alert_count: $bc, broken: $broken}' > "$OUT"

if [ "$BROKEN_COUNT" -gt 0 ]; then
  echo "ALERT: $BROKEN_COUNT broken links of $TOTAL checked"
  exit 1
fi
echo "OK: $TOTAL links healthy"
