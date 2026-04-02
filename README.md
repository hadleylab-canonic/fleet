# FLEET

Governed monitoring agents for CANONIC infrastructure. Bash scripts check public surfaces on a schedule. No LLM on the hot path.

## Tasks

| Task | Schedule | Monitors |
|------|----------|----------|
| UPTIME | hourly | Domain health + SSL for hadleylab.org, canonic.org, mammochat.com, caribchat.ai |
| BUILD | hourly | GitHub Actions deploy status for all fleet sites |
| HN-SCOUT | 2h | HackerNews threads relevant to healthcare AI governance |
| CAMPAIGN | hourly | HN emission engagement (points, comments) |
| GRANTS | daily | Deadline proximity alerts (T-30d, T-14d, T-7d, T-1d) |
| LINKS | daily | External URL validation in blog Sources tables |
| SEO | daily | robots.txt, sitemap.xml, OG tags across 4 domains |
| CITATIONS | weekly | Bibliography URL freshness |

## How It Works

1. Each task has a `## TASK Contract` in its service CANON.md (in [hadleylab-canonic](https://github.com/hadleylab-canonic/hadleylab-canonic))
2. Scripts in `scripts/` implement the monitoring (bash, no dependencies)
3. GitHub Actions runs them on schedule
4. Results committed to `_data/*.json`
5. Alerts surface as non-zero exit codes in the workflow

## Governance

This repo is governed by `hadleylab-canonic/SERVICES/TASK`. Scripts carry `_generated` markers — edit the TASK Contract, not the script.

---

*FLEET | hadleylab-canonic/SERVICES/TASK*
