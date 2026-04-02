#!/usr/bin/env bash
# _generated — edit the TASK Contract in SERVICES/BUILD/CANON.md, not this file
# BUILD: check GitHub Actions deploy status
set -euo pipefail
REPO_DIR="${REPO_DIR:-.}"

OUT="_data/BUILD.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REPOS=("hadleylab-canonic/hadleylab-canonic.github.io" "canonic-canonic/canonic-canonic.github.io")
ALERTS=()

echo '{"_generated": true, "task": "BUILD", "timestamp": "'"$NOW"'", "results": [' > "$OUT.tmp"

FIRST=true
for repo in "${REPOS[@]}"; do
  RESULT=$(curl -sH "Authorization: Bearer ${GITHUB_TOKEN:-}" \
    "https://api.github.com/repos/$repo/actions/runs?per_page=1" 2>/dev/null)

  STATUS=$(echo "$RESULT" | jq -r '.workflow_runs[0].status // "unknown"' 2>/dev/null || echo "unknown")
  CONCLUSION=$(echo "$RESULT" | jq -r '.workflow_runs[0].conclusion // "unknown"' 2>/dev/null || echo "unknown")
  CREATED=$(echo "$RESULT" | jq -r '.workflow_runs[0].created_at // "unknown"' 2>/dev/null || echo "unknown")

  if [ "$FIRST" = true ]; then FIRST=false; else echo ',' >> "$OUT.tmp"; fi
  echo '  {"repo": "'"$repo"'", "status": "'"$STATUS"'", "conclusion": "'"$CONCLUSION"'", "created_at": "'"$CREATED"'"}' >> "$OUT.tmp"

  if [ "$CONCLUSION" = "failure" ]; then
    ALERTS+=("$repo: deploy FAILED")
  fi
done

echo '], "alert_count": '"${#ALERTS[@]}"'}' >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"

if [ ${#ALERTS[@]} -gt 0 ]; then
  echo "ALERT: ${ALERTS[*]}"
  exit 1
fi
echo "OK: all deploys passing"
