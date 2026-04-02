#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/UPTIME/CANON.md, not this file
# UPTIME: curl health checks + SSL expiry for all product domains
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/UPTIME.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DOMAINS=(hadleylab.org canonic.org mammochat.com caribchat.ai app.mammochat.ai app.caribchat.ai)
ALERTS=()

echo '{"_generated": true, "task": "UPTIME", "timestamp": "'"$NOW"'", "results": [' > "$OUT.tmp"

FIRST=true
for domain in "${DOMAINS[@]}"; do
  STATUS=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 15 "https://$domain/" 2>/dev/null || echo "000")
  TIME_MS=$(curl -sI -o /dev/null -w '%{time_total}' --connect-timeout 10 --max-time 15 "https://$domain/" 2>/dev/null || echo "0")
  TIME_MS=$(echo "$TIME_MS * 1000" | bc 2>/dev/null || echo "0")

  # SSL expiry
  SSL_EXPIRY=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//' || echo "unknown")
  if [ "$SSL_EXPIRY" != "unknown" ]; then
    SSL_EPOCH=$(date -d "$SSL_EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$SSL_EXPIRY" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    SSL_DAYS_LEFT=$(( (SSL_EPOCH - NOW_EPOCH) / 86400 ))
  else
    SSL_DAYS_LEFT=-1
  fi

  if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$OUT.tmp"; fi
  echo '  {"domain": "'"$domain"'", "status": '"$STATUS"', "time_ms": '"${TIME_MS%.*}"', "ssl_expiry": "'"$SSL_EXPIRY"'", "ssl_days_left": '"$SSL_DAYS_LEFT"'}' >> "$OUT.tmp"

  # Alert conditions
  if [ "$STATUS" -lt 200 ] || [ "$STATUS" -ge 400 ]; then
    ALERTS+=("$domain: HTTP $STATUS")
  fi
  if [ "$SSL_DAYS_LEFT" -gt 0 ] && [ "$SSL_DAYS_LEFT" -lt 30 ]; then
    ALERTS+=("$domain: SSL expires in ${SSL_DAYS_LEFT}d")
  fi
done

echo '], "alert_count": '"${#ALERTS[@]}"'}' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"

if [ ${#ALERTS[@]} -gt 0 ]; then
  echo "ALERT: ${ALERTS[*]}"
  exit 1
fi
echo "OK: all ${#DOMAINS[@]} domains healthy"
