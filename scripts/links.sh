#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/BLOG/CANON.md, not this file
# LINKS: validate external URLs in blog Sources tables
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/LINKS.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BROKEN=()
TOTAL=0

# Extract URLs from ## Sources tables in ${REPO_DIR}/BLOGS/*.md
URLS=$(grep -rhoP 'https?://[^\s\)\]>"]+' ${REPO_DIR}/BLOGS/*.md 2>/dev/null | sort -u | head -100)

echo '{"_generated": true, "task": "LINKS", "timestamp": "'"$NOW"'", "broken": [' > "$OUT.tmp"

FIRST=true
for url in $URLS; do
  TOTAL=$((TOTAL + 1))
  STATUS=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 15 "$url" 2>/dev/null || echo "000")
  sleep 1  # polite rate limit

  if [ "$STATUS" -lt 200 ] || [ "$STATUS" -ge 400 ]; then
    if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$OUT.tmp"; fi
    echo '  {"url": "'"$url"'", "status": '"$STATUS"'}' >> "$OUT.tmp"
    BROKEN+=("$url")
  fi
done

echo '], "total_checked": '"$TOTAL"', "broken_count": '"${#BROKEN[@]}"', "alert_count": '"${#BROKEN[@]}"'}' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"

if [ ${#BROKEN[@]} -gt 0 ]; then
  echo "ALERT: ${#BROKEN[@]} broken links of $TOTAL checked"
  exit 1
fi
echo "OK: $TOTAL links healthy"
