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
won't appear here, but `flags.unfinished_update_logs` shows the
start_time of any in-flight (or orphaned) update, so "how long has the
current run been going" is answerable. `flags.update_logs` holds the
last ~10 completed updates — compute their durations; a uniform
duration across runs means steady-state cost, not a one-off stall.

**`processed` / `reprocessed` count TIMESLICES, not revisions** (one
per `handle_timeslice` leaf in `UpdateCourseWikiTimeslices`). Each
processed timeslice costs one `revisions.php` query to
replica-revision-tools per wiki, whether or not it contains any
revisions.

From `users.json`, extract `users[].username` (filter by `role` —
role 0 = student, 1 = instructor). **Only role-0 students are tracked
for revisions** (`CourseRevisionUpdater` uses `course.students`), so
recent edits by instructors/facilitators are irrelevant to update cost.

## Step 3 — Identify the cost shape

Two distinct shapes produce long updates; pick the probe accordingly:

- **Revision-volume shape** (active course, many edits): cost is
  dominated by per-revision work (ref-counter, Lift Wing, diff
  analysis). Tell: `processed` is modest but durations scale with
  recent edit volume. → Step 4.
- **Empty-timeslice-scan shape** (dormant course, end date far in the
  future): cost is dominated by scanning empty daily timeslices, one
  replica query each. Tells: `processed` ≫ the course's lifetime
  `edit_count`; every update in `update_logs` has near-identical
  duration and `processed` count; `processed` grows by exactly
  (number of tracked wikis) per day. → Step 5.

Mechanism of the second shape: `TimesliceManager#get_ingestion_start_time_for_wiki`
pins the ingestion start at the timeslice containing the **latest
tracked student revision** (max `last_mw_rev_datetime`). Empty
timeslices never advance that watermark (`process_timeslices` is
skipped when there's no new data), so every update re-scans every
daily timeslice from the last student edit to today, per wiki,
forever — the window grows by 1 slice/wiki/day until course end.

## Step 4 — Revision-volume shape: bucket contributions along the three cost axes

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

**Gotcha**: `list=usercontribs` with multiple `ucuser` values returns
per-user blocks, NOT timestamp-merged results, and caps at 50 users —
never use a multi-user usercontribs query to find "the latest edit by
any of these users". Query the replica endpoint instead (below), which
also matches the updater's own tracked-namespace filtering.

## Step 5 — Empty-timeslice-scan shape: probe the watermark gap

Use `benchmarks/probe_timeslice_gap.rb` — it queries the **same
endpoint the updater uses** (`revisions.php` on
replica-revision-tools.wmcloud.org) to find each wiki's watermark
(latest tracked student revision), computes the expected
timeslice-scan count, times empty-day queries for the per-slice unit
cost, and projects runtime:

```bash
SLUG='tlv_university/TLV_University,_Science_Oriented_Youth_-_Alpha_Program_-_Cycle_C_(2016-2017)' \
  ruby benchmarks/probe_timeslice_gap.rb
```

Expected scans = Σ over wikis of (days from the timeslice containing
the last student edit, through today, inclusive; slice boundaries are
aligned to the course start time-of-day). If this matches
`last_update.processed` exactly (small positive excess = split
timeslices), the diagnosis is confirmed. Calibration (course 10781,
2026-08-20): ~0.25–0.30 s per empty-slice replica query + ~35%
Rails-side overhead ≈ 0.35 s/slice end-to-end; 3,867 slices → 22.9 min
per update, ~10×/day.

Querying the replica endpoint directly (what the script does):

```
https://replica-revision-tools.wmcloud.org/revisions.php?lang=he&project=wikipedia&usernames[]=A&usernames[]=B&start=YYYYMMDDHHMMSS&end=YYYYMMDDHHMMSS
```

Response is `{"success":true,"data":[...]}` with `rev_timestamp`
fields. For wikis with nonstandard db names use `db=` instead of
`lang=`/`project=` (wikidata → `db=wikidatawiki`, commons →
`db=commonswiki`; full list in `Replica::SPECIAL_DB_NAMES`). A
malformed/unknown project silently falls back to a bogus db and
returns a 502 "Cannot connect to database" error — check
`success:false` bodies rather than assuming the service is down.

## Step 6 — Sanity-check projection vs. observed runtime

Compare projected wall time to:
- The user's reported runtime ("update has been running 9 hours")
- `updates.average_delay` (seconds between completed updates) — if
  the projection is way under average_delay, an external factor
  (Toolforge service down, Lift Wing slow, etc.) is likely the
  culprit, not the course's edit volume.

If projected « observed: it's a service-availability problem, not a
scale problem. If projected ≈ observed: it's pure scale and a
reference-counter / Lift Wing batch fix would help.

## Step 7 — Report

Summarize for the user:
- Course shape (home_wiki, # users, window, last completed update)
- Which cost shape it is, and the per-axis / per-wiki numbers
- Projected runtime range (low/high) vs. observed
- Whether projected runtime explains observed runtime, or whether a
  different bottleneck is implicated (and which one to investigate
  next — Toolforge tool status, Lift Wing latency, etc.)
- For the empty-timeslice-scan shape, also report the daily waste
  (updates/day × duration) and growth rate — the interesting question
  becomes "how many other courses have this shape", since every
  dormant course with a far-future end date burns worker time on
  every cycle until its end date.

## Reference files

- `benchmarks/probe_course_contributions.rb` — revision-volume probe;
  drives off `SLUG` env var
- `benchmarks/probe_timeslice_gap.rb` — empty-timeslice-scan probe;
  drives off `SLUG` env var; validated 2026-08-20 against course 10781
  (predicted processed=3867 exactly; projected 22.1 min vs 22.9 observed)
- `benchmarks/cuwprofile_http.rb` — per-HTTP-call profiler for a real
  UpdateCourseStats run (dev DB only, not prod recon); supports
  `MODE=cold|warm|incremental|cold+warm`
- `.claude/plans/benchmark_notes-2026-04-24.md` — cost model
  derivation + per-endpoint timings
- `.claude/plans/plan_course_update_perf_regression-2026-04-24.md` —
  loose ends from the 35819 investigation (UploadImporter, sidekiq-status TTL, etc.)
