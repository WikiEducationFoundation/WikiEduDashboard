---
name: course-update-recon
description: Characterize a slow / stuck course-update worker on dashboard.wikiedu.org or outreachdashboard.wmflabs.org. Use this skill when asked to investigate why a course update is taking unusually long, hung, or running for many hours, or to estimate the scale-of-work of an in-flight update. Pure HTTP recon against public APIs — never SSH into prod.
---

# Course-update recon

Workflow for characterizing a slow or stuck course update without ever
touching prod. The goal is a per-axis estimate of the work-in-flight
(or work-just-completed) so we can predict runtime and pick a fix.

**Hard rule: never SSH to peony-web, peony-database, peony-sidekiq*,
dashboard.wikiedu.org, or any other prod host.** All recon is via
public dashboard JSON endpoints + public Wikimedia APIs. If you need
something only available inside the prod app, ask the user to run a
one-liner and paste the result back.

## Step 1 — Resolve course id → slug

The numeric id is what the user usually has; the public JSON endpoints
key on slug. The `/find_course/<id>` endpoint redirects from id to the
canonical course URL — read the `Location:` header to get the slug:

```bash
curl -sSI -A "WikiEdu-Dashboard-Recon/1.0 (sage@wikiedu.org)" \
  https://outreachdashboard.wmflabs.org/find_course/<ID> | grep -i location
# Location: https://outreachdashboard.wmflabs.org/courses/<SLUG>
```

For Wiki Ed Dashboard courses use `https://dashboard.wikiedu.org/find_course/<ID>`.
Slugs may contain `'`, `:` etc. — URL-encode before hitting the JSON
endpoints.

## Step 2 — Pull course.json + users.json

```bash
SLUG_ENC="...url-encoded slug..."
HOST=https://outreachdashboard.wmflabs.org   # or dashboard.wikiedu.org

curl -sS "$HOST/courses/$SLUG_ENC/course.json"
curl -sS "$HOST/courses/$SLUG_ENC/users.json"
```

From `course.json`, note: `start`, `end`, `home_wiki`, `wikis`,
`updates.average_delay`, and `updates.last_update` (start_time,
end_time, processed, reprocessed). The `last_update.end_time` is the
**last completed** update — if a worker is currently running, it
won't appear here.

From `users.json`, extract `users[].username` (filter by `role` if you
want to exclude instructors/staff — role 0 = student, 1 = instructor).

## Step 3 — Bucket contributions along the three cost axes

Per the 2026-04-24 benchmark (`.claude/plans/benchmark_notes-2026-04-24.md`):

| Axis | Per-unit cost | Driver |
|---|---:|---|
| Non-wikidata (enwiki etc.) ns=0 revs | **~4 s/rev** | ReferenceCounter (2× per rev) + Lift Wing |
| Wikidata revs (any ns) | **~0.2 s/rev** | Replica + WikidataDiffAnalyzer (batched) |
| Commons uploads | 0.5 s (healthy) – 10 s (observed stalled) per upload | UploadImporter serial thumburl + usage_count |

Use `benchmarks/probe_course_contributions.rb` — it runs the recon
against `list=usercontribs` for ns=0 on each non-wikidata wiki,
`list=usercontribs` (all ns) on wikidata, and `list=allimages` on
Commons, then projects total runtime from the per-axis costs.

```bash
SLUG='Polskojęzyczna_Wikipedia/Wikiprojekt_Nauki_medyczne' \
  ruby benchmarks/probe_course_contributions.rb
```

Required env: `SLUG` (course slug). Optional: `HOST` (default
outreachdashboard.wmflabs.org; switch to dashboard.wikiedu.org for
Wiki Ed courses), `WINDOW_START` / `WINDOW_END` to narrow the probe
window, `PER_USER_CAP` to raise the per-user pagination cap (default
5000), `USERS_LIMIT` to spot-check a subset.

## Step 4 — Sanity-check projection vs. observed runtime

Compare projected wall time to:
- The user's reported runtime ("update has been running 9 hours")
- `updates.average_delay` (seconds between completed updates) — if
  the projection is way under average_delay, an external factor
  (Toolforge service down, Lift Wing slow, etc.) is likely the
  culprit, not the course's edit volume.

If projected « observed: it's a service-availability problem, not a
scale problem. If projected ≈ observed: it's pure scale and a
reference-counter / Lift Wing batch fix would help.

## Step 5 — Report

Summarize for the user:
- Course shape (home_wiki, # users, window, last completed update)
- Per-axis edit counts in the window
- Projected runtime range (low/high)
- Whether projected runtime explains observed runtime, or whether a
  different bottleneck is implicated (and which one to investigate
  next — Toolforge tool status, Lift Wing latency, etc.)

## Reference files

- `benchmarks/probe_course_contributions.rb` — generic per-axis probe;
  drives off `SLUG` env var
- `benchmarks/cuwprofile_http.rb` — per-HTTP-call profiler for a real
  UpdateCourseStats run (dev DB only, not prod recon); supports
  `MODE=cold|warm|incremental|cold+warm`
- `.claude/plans/benchmark_notes-2026-04-24.md` — cost model
  derivation + per-endpoint timings
- `.claude/plans/plan_course_update_perf_regression-2026-04-24.md` —
  loose ends from the 35819 investigation (UploadImporter, sidekiq-status TTL, etc.)
