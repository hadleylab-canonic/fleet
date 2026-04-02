#!/usr/bin/env bash
# _generated — edit the TASK Contract in ${REPO_DIR}/SERVICES/CITATION/CANON.md, not this file
# CITATIONS: validate bibliography URLs (weekly)
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/CITATIONS.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BIBO="${REPO_DIR}/SERVICES/CITATION/BIBLIOGRAPHY.md"
BROKEN=()
TOTAL=0

if [ ! -f "$BIBO" ]; then
  echo '{"_generated": true, "task": "CITATIONS", "timestamp": "'"$NOW"'", "error": "BIBLIOGRAPHY.md not found"}' > "$OUT"
  echo "SKIP: $BIBO not found"
  exit 0
fi

URLS=$(grep -oP 'https?://[^\s\)\]>"]+' "$BIBO" 2>/dev/null | sort -u | head -200)

echo '{"_generated": true, "task": "CITATIONS", "timestamp": "'"$NOW"'", "broken": [' > "$OUT.tmp"

FIRST=true
for url in $URLS; do
  TOTAL=$((TOTAL + 1))
  STATUS=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 15 "$url" 2>/dev/null || echo "000")
  sleep 1

  if [ "$STATUS" -lt 200 ] || [ "$STATUS" -ge 400 ]; then
    if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$OUT.tmp"; fi
    echo '  {"url": "'"$url"'", "status": '"$STATUS"'}' >> "$OUT.tmp"
    BROKEN+=("$url")
  fi
done

echo '], "total_checked": '"$TOTAL"', "broken_count": '"${#BROKEN[@]}"', "alert_count": '"${#BROKEN[@]}"'}' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"

if [ ${#BROKEN[@]} -gt 0 ]; then
  echo "ALERT: ${#BROKEN[@]} broken citations of $TOTAL checked"
  exit 1
fi
echo "OK: $TOTAL citation URLs healthy"
