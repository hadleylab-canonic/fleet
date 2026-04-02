# FLEET — CANON

inherits: hadleylab-canonic/SERVICES/TASK

---

## Axiom

**FLEET is the monitoring runtime for CANONIC infrastructure. Bash scripts check public surfaces. No LLM on the hot path. Zero cost at scale. Claude writes the scripts; GitHub Actions runs them.**

---

## Constraints

```
MUST:     Discover scripts via scripts/*.sh (glob, not hardcoded)
MUST:     Each script corresponds to a ## TASK Contract in a service CANON.md
MUST:     Scripts are read-only observers — curl, check, report
MUST:     All outputs written to _data/{TASK_NAME}.json with _generated marker
MUST:     Scripts exit 1 on alert, 0 on healthy — workflow uses exit code for commit message
MUST:     Commit results only when _data/ changes (no empty commits)
MUST:     Rate limit: max 1 request per second per external platform
MUST NOT: Store credentials in scripts (use GitHub Secrets + env vars)
MUST NOT: Post, comment, or engage on any external platform
MUST NOT: Modify any file outside _data/
MUST NOT: Include proprietary IP (dimension codes, bitmask formulas, internal architecture)
```

---

## Script Contract

Each `scripts/*.sh` declares in its header comment:
- `_generated` marker (edit the TASK Contract, not the script)
- Source service CANON.md path
- Task name matching the TASK Contract

Scripts receive these environment variables:
- `GITHUB_TOKEN` — GitHub Actions automatic token (for API calls)
- No other secrets required (all monitoring targets are public)

---

## Schedule

| Task | Script | Schedule | What It Checks |
|------|--------|----------|----------------|
| UPTIME | uptime.sh | hourly | Domain health + SSL expiry |
| BUILD | build.sh | hourly | GitHub Actions deploy status |
| HN-SCOUT | hn-scout.sh | every 2h | HN thread discovery |
| CAMPAIGN | campaign.sh | hourly | HN emission engagement |
| GRANTS | grants.sh | daily | Deadline proximity |
| LINKS | links.sh | daily | Blog source URL validation |
| SEO | seo.sh | daily | Sitemap, robots.txt, OG tags |
| CITATIONS | citations.sh | weekly | Bibliography URL validation |

---

## Architecture

```
hadleylab-canonic/SERVICES/*/CANON.md    (GOV: ## TASK Contract declarations)
  → Claude writes scripts once             (compile time)
    → hadleylab-canonic/fleet/scripts/     (public, governed, _generated)
      → GitHub Actions cron                (runtime, free)
        → _data/*.json                     (results, committed back)
          → alert exit code → commit msg   (observability)
```

---

*FLEET | CANON | TASK*
