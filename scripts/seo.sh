#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/SEO/CANON.md, not this file
# SEO: check robots.txt, sitemap.xml, OG tags
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/SEO.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DOMAINS=(hadleylab.org canonic.org mammochat.com caribchat.ai)
ALERTS=()

echo '{"_generated": true, "task": "SEO", "timestamp": "'"$NOW"'", "results": [' > "$OUT.tmp"

FIRST=true
for domain in "${DOMAINS[@]}"; do
  ROBOTS=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://$domain/robots.txt" 2>/dev/null || echo "000")
  SITEMAP=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://$domain/sitemap.xml" 2>/dev/null || echo "000")

  # Count sitemap URLs
  SITEMAP_COUNT=0
  if [ "$SITEMAP" -ge 200 ] && [ "$SITEMAP" -lt 400 ]; then
    SITEMAP_COUNT=$(curl -s --connect-timeout 10 "https://$domain/sitemap.xml" 2>/dev/null | grep -c '<loc>' || echo "0")
  fi

  # Check OG tags on index
  OG_TITLE=$(curl -sL --connect-timeout 10 "https://$domain/" 2>/dev/null | grep -c 'og:title' || echo "0")

  if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$OUT.tmp"; fi
  echo '  {"domain": "'"$domain"'", "robots": '"$ROBOTS"', "sitemap": '"$SITEMAP"', "sitemap_urls": '"$SITEMAP_COUNT"', "og_title": '"$OG_TITLE"'}' >> "$OUT.tmp"

  if [ "$ROBOTS" -ge 400 ]; then ALERTS+=("$domain: robots.txt missing"); fi
  if [ "$SITEMAP" -ge 400 ]; then ALERTS+=("$domain: sitemap.xml missing"); fi
  sleep 1
done

echo '], "alert_count": '"${#ALERTS[@]}"'}' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"

if [ ${#ALERTS[@]} -gt 0 ]; then
  echo "ALERT: ${ALERTS[*]}"
  exit 1
fi
echo "OK: all ${#DOMAINS[@]} domains SEO healthy"
