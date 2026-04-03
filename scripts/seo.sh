#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/SEO/CANON.md, not this file
# SEO: check robots.txt, sitemap.xml, OG tags
set -uo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/SEO.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DOMAINS=(hadleylab.org canonic.org mammochat.com caribchat.ai)

RESULTS="[]"
ALERT_COUNT=0

for domain in "${DOMAINS[@]}"; do
  ROBOTS=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://$domain/robots.txt" 2>/dev/null || echo "000")
  SITEMAP=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://$domain/sitemap.xml" 2>/dev/null || echo "000")
  SITEMAP_COUNT=0
  if [ "$SITEMAP" -ge 200 ] && [ "$SITEMAP" -lt 400 ]; then
    SITEMAP_COUNT=$(curl -s --connect-timeout 10 "https://$domain/sitemap.xml" 2>/dev/null | grep -c '<loc>' || echo "0")
  fi
  OG=$(curl -sL --connect-timeout 10 "https://$domain/" 2>/dev/null | grep -c 'og:title' || echo "0")

  ISSUES=""
  [ "$ROBOTS" -ge 400 ] 2>/dev/null && ISSUES="robots.txt missing" && ALERT_COUNT=$((ALERT_COUNT + 1))
  [ "$SITEMAP" -ge 400 ] 2>/dev/null && ISSUES="${ISSUES:+$ISSUES, }sitemap.xml missing" && ALERT_COUNT=$((ALERT_COUNT + 1))
  [ "$OG" -eq 0 ] 2>/dev/null && ISSUES="${ISSUES:+$ISSUES, }og:title missing"

  RESULTS=$(echo "$RESULTS" | jq --arg d "$domain" --arg r "$ROBOTS" --arg sm "$SITEMAP" \
    --arg sc "$SITEMAP_COUNT" --arg og "$OG" --arg iss "${ISSUES:-none}" \
    '. + [{domain: $d, robots: ($r | tonumber), sitemap: ($sm | tonumber), sitemap_urls: ($sc | tonumber), og_title: ($og | tonumber), issues: $iss}]')
  sleep 1
done

jq -n --argjson results "$RESULTS" --arg ts "$NOW" --argjson ac "$ALERT_COUNT" \
  '{_generated: true, task: "SEO", timestamp: $ts, results: $results, alert_count: $ac}' > "$OUT"

if [ "$ALERT_COUNT" -gt 0 ]; then
  echo "ALERT: $ALERT_COUNT SEO issues"
  exit 1
fi
echo "OK: all ${#DOMAINS[@]} domains SEO healthy"
