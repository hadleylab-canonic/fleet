#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/CAMPAIGN/CANON.md, not this file
# CAMPAIGN: poll emission engagement, accumulate temporal snapshots, detect SLA breaches
set -euo pipefail

OUT="SERVICES/TASK/_data/CAMPAIGN.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
METRICS_SCRIPT="$HOME/.canonic/bin/build-campaigns-metrics"

# Prefer the Python metrics compiler if available
if [ -f "$METRICS_SCRIPT" ] && command -v python3 &>/dev/null; then
  echo "CAMPAIGN: running build-campaigns-metrics (temporal snapshots)"
  python3 "$METRICS_SCRIPT" "$(pwd)"

  # Copy summary to TASK output for FLEET dashboard
  METRICS="CAMPAIGNS/_data/METRICS.json"
  if [ -f "$METRICS" ]; then
    python3 -c "
import json, sys
m = json.load(open('$METRICS'))
out = {
    '_generated': True,
    'task': 'CAMPAIGN',
    'timestamp': '$NOW',
    'polled_at': m.get('polled_at', '$NOW'),
    'emission_count': len(m.get('emissions', {})),
    'snapshot_count': sum(len(e.get('snapshots', [])) for e in m.get('emissions', {}).values()),
    'campaigns': m.get('campaigns', {}),
    'channels': m.get('channels', {}),
}
json.dump(out, open('$OUT', 'w'), indent=2)
print(f'OK: {out[\"emission_count\"]} emissions, {out[\"snapshot_count\"]} snapshots')
"
  fi
else
  # Fallback: basic HN-only poll (original behavior)
  echo "CAMPAIGN: fallback to basic HN poll (Python script not available)"
  HN_IDS=$(grep -rhoP '(?:posted_id|hn_id|objectID)[:\s]+(\d+)' CAMPAIGNS/ 2>/dev/null | grep -oP '\d+' | sort -u | head -20)

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
fi
