# Whole-class group projects: research plan

Status: planning (started 2026-09-29). Scope: Wiki Education Dashboard only.

(Plan and status log written by Claude Code.)

## Question

Some classes have the whole class — often with the instructor — collaborate on
a single article or a very small number of articles. Does that mode produce
better-quality contributions than individual or small-group projects?

Hypothesis: everyone-on-the-same-side projects mitigate AI usage and the content
problems associated with it. Students work in small units and are accountable to
each other, so there is less incentive to use AI as a shortcut, more social cost
to checking out and posting slop, and a better chance that the instructor or
classmates catch hallucinations and claims their sources don't support.

## Ground rules

- **Quality signals are the primary outcomes.** AI-detection signals (Pangram
  scores, AI edit alerts) are a supplement only.
- **LLM-forward.** There is no staff capacity for major human review. LLMs do
  classification validation and content/sourcing judgments, with blinding and
  calibration in place of human coding. The only human step planned is a quick
  review of the final whole-class course list.
- **No private data goes through an LLM** — including the coding agent running
  the analysis. See Phase 0.
- **Nothing touches production.** The work starts from a local copy of the
  production database.
- **Data stays local.** This repo is public. `data/`, `*.csv`, `*.sql.gz` and
  `*dump*.sql` under `docs/analytics_scripts/` are gitignored; scripts (query
  files included) and this plan are committed, the data they read and write is not.

## Inputs

- `dashboard-dump-2026-09-27-20:00:01.sql.gz` — raw production dump. Keep it
  outside the repo, in `~/whole_class_projects/`. Must not be read by an LLM.
  Keep it until Phase 1 confirms the allowlist has every needed column, then
  delete it (README.md step 6).
- Public MediaWiki and LiftWing APIs, for revision history, page content and
  article quality.

Note that production no longer stores individual revisions: the dump has
aggregates (`articles_courses`, `article_course_timeslices`,
`article_course_user_wiki_timeslices`). The dump is for defining cohorts and
pointing at the right edits; most quality evidence comes from Wikipedia.

## Phase 0: Sanitize

**Who handles raw data.** The agent writes the sanitization scripts from
`db/schema.rb` alone, never querying the raw database. The operator:

1. Loads the raw dump into a staging database.
2. Runs the sanitization script, which builds a new sanitized database from it.
3. Runs the audit script and confirms it is clean.
4. Grants the agent's MySQL user read access to the sanitized database only.
5. Once Phase 1 confirms nothing is missing, drops the staging database and
   deletes the raw dump.

All later work uses only the sanitized database. The runbook is README.md; the
scripts are `sanitize.rb` and `audit_sanitized.rb`.

**Allowlist, not denylist.** Only the tables and columns the analysis needs are
copied, so anything added to the schema later is excluded by default.

| Keep | Remove or transform |
|---|---|
| `courses`: dates, school, title, term, subject, level, type, counts, description | `passcode`, `chatroom_id`, `syllabus_*`, `flags`; description scrubbed (below) |
| `courses_users`: course, user, role, character and reference counts | `real_name`, `role_description` |
| `users`: id, username, global id, registration and first-login dates, trained flag | `real_name`, `email`, tokens, secrets, `chat_*` |
| `assignments`, `articles`, `articles_courses`, timeslice tables, `weeks`, `campaigns`, `campaigns_courses`, `courses_wikis`, `wikis` | Kept as-is, including userspace titles and sandbox URLs |
| `blocks`: kind, dates, training module ids, title, content | Content and title scrubbed |
| `alerts`: type, course, article, user, timestamps | `message`, `details` (staff-written, mention names) |
| `revision_ai_scores`: score numbers only | `details`, `url` |

**Dropped entirely:** `user_profiles`, `requested_accounts`, ticket tables,
survey and rapidfire tables, `feedback_form_responses`, `admin_course_notes`,
all `lti_*` tables, `versions` (PaperTrail stores full copies of old records),
`verification_claim_responses`, `experiment_courses_users`, `settings`,
`backups`.

**Free-text scrubbing.** Course descriptions and timeline text are needed for
mode classification. Before the name columns are dropped, the script:

- Replaces every real name and email of anyone enrolled in that course, and of
  Wiki Education staff, with a role token (`[INSTRUCTOR_1]`, `[STUDENT_7]`).
- Applies general patterns for email addresses and phone numbers.
- Treats private courses (`courses.private`) more strictly: counts and
  structure are kept, free text is dropped.

School and course title are kept (useful for matching on discipline and
institution); titles get the same name scrubbing as other free text.

**Usernames are not sanitized.** Only real names and emails are treated as
private. Usernames, userspace titles and sandbox URLs stay as they are, and
Wikipedia-side scripts link revisions to students by username directly.

**Audit.** An operator-run script fails if private-looking columns (real names,
emails, tokens) remain. It also counts leftover real names and emails in text
columns as warnings; the operator decided on 2026-09-29 that those don't need
removing. Output is counts and schema names only.

## Phase 1: Classify courses by collaboration mode

- Compute a concentration score for every course: the share of assigned-editing
  students (role 0) on the course's top 1–3 articles, and students per distinct
  article, from `assignments`, `articles_courses.user_ids` and
  `article_course_user_wiki_timeslices`. Using both assignments and actual edits
  catches classes that collaborate without recording it, and ones that record
  shared assignments but split up in practice.
- Flag instructor co-editing of the same articles.
- Groups: **whole-class**, **small-group** (2–5 students per article),
  **individual**. The middle group gives a dose-response check.
- No seed list exists. An LLM reads each candidate's (sanitized) description,
  timeline text and assignment spread and labels the mode with a stated reason.
- Run a threshold sensitivity sweep: report which courses change group at
  different cutoffs, and run every downstream result at more than one threshold.
- Human step: the operator skims the final whole-class list (expected 30–60
  courses).

Time window: every term the data covers, split at ChatGPT's release (late 2022)
into pre- and post-AI eras.

## Phase 2: Quality signals

**From the sanitized database** (every course):

- Characters and references added per student and per article; new vs.
  expanded articles.
- Recorded judgments: `BadWorkAlert`, `PossiblePlagiarismAlert`,
  `ArticlesForDeletionAlert` (negative); `DYKNominationAlert`,
  `GANominationAlert` (positive).

**From Wikipedia** (the core of the analysis):

- **Survival:** share of added text still present at 30 days, 6 months and
  today; whether it was lost to a revert or removed by editors outside the
  class.
- **Outside-editor reaction:** reverts, cleanup or maintenance tags added after
  the class's edits ("citation needed", "essay-like", "original research"),
  talk-page complaints.
- **Before/after article quality:** change in LiftWing article-quality score
  from before the class's first edit to end of term; talk-page assessment class.
- **Sourcing:** citation density in added text, source types, citation reuse.

**LLM-graded content quality** (stratified sample, starting at 300–500
articles/excerpts across the three modes and both eras; expand as budget
allows):

- **Blinded:** the grader never sees the course, mode or term — only the
  before/after article excerpt, the diff text and the cited sources.
- **Fixed rubric**, written and locked before any scoring: claims supported by
  their cited source; encyclopedic tone; original research or essay-like
  writing; fit with the article's structure; citations exist and match the text.
- **Source checking:** fetch cited sources where reachable (open access, DOI
  landing pages, Internet Archive). Paywalled sources are marked unverifiable,
  not guessed; the unverifiable rate is reported as its own result, since it
  likely differs between groups.
- **Calibration without humans:** mix in known-quality anchors (content that
  reached GA; content that was reverted or tagged); grade a subset with two
  different models; re-grade a subset to check stability. Model disagreements
  are reported as uncertain, not resolved by a person.
- **Pilot first:** ~50 items to check cost, inter-model agreement and whether
  the rubric works, before the full run.
- Cheaper models (Sonnet or Haiku) for the bulk grading, small batches,
  incremental writes, cached so runs can resume.

## Phase 3: Comparisons and confounders

- **Same-instructor comparison:** the same instructor in group-project terms
  vs. individual terms. The strongest comparison available, since instructors
  who choose group projects are unusual.
- **Otherwise matched:** subject, course level, class size, sandbox-first vs.
  live editing.
- **Normalize for mode:** shared articles attract more editors and outside
  attention, so outcomes are per character added and per student, not per
  article.
- **AI hypothesis without detectors:** does the quality gap between modes grow
  after 2022? If individual projects got worse post-ChatGPT and whole-class
  projects didn't, that supports the hypothesis.
- **AI signals as a supplement:** where `revision_ai_scores` or AI edit alerts
  exist (Fall 2025 on), add them as one extra column.

## Phase 4: Mechanisms

- Individual edit size and frequency.
- How often students edit or fix each other's text; whether problems are caught
  by the class or by outside editors.
- Instructor edit volume and timing.
- In-class talk-page discussion.

## Layout

```
docs/analytics_scripts/whole_class_projects/
  PLAN.md      this file (committable)
  *.rb, *.py   scripts (committable)
  data/        sanitized DB exports, caches, CSVs (gitignored)
```

## Status

- 2026-09-29: Phase 0 done on the 2026-09-27 dump (audit rule: only real-name
  and email columns must be gone; leftover names in text are acceptable).
- 2026-09-29: Phase 1 metrics built (`phase1_collab_metrics.rb`). Findings:
  - Editor lists (`articles_courses.user_ids`) exist only for 2020+ courses;
    assignments cover 2015+. `article_course_user_wiki_timeslices` is empty in
    the dump.
  - Mainspace-only signals mislabel sandbox-heavy individual courses whose
    only mainspace work was a shared exercise article, so the assignment
    signal is primary.
  - Rule-based modes (>=6 assigned students): whole_class 105 (75 pre-2023,
    30 from 2023), small_group 1,224, individual 3,743, other 69; 2,890
    courses lack enough assignment data.
  - `phase1_review_packets.rb` wrote 641 LLM review packets (candidate pools
    plus 77 small-group/individual controls).
- 2026-09-29: LLM labels done (Sonnet subagents, 4 concurrent, rubric in
  `phase1_label_rubric.md`; packets blinded to pool and rule label). Output:
  `data/phase1_labels_all.jsonl`, `wcp_analysis.course_mode_labels`.
  - Controls: 0 of 77 small-group/individual controls labeled whole-class.
  - Rule whole-class (105): LLM agrees on 75, 12 unclear, 18 other modes.
  - LLM whole-class total 131 (48 high, 53 medium, 30 low confidence);
    103 pre-2023, 28 from 2023.
  - 103 of 203 no-editor-data courses are unclear; instructor participation
    is never stated in course text (all `unknown`).
- 2026-09-29: Page histories fetched for all 641 labeled courses
  (`phase1_page_histories.rb`: 2,355 course-article pages, 73,504 in-window
  revisions in `data/phase1_revisions.jsonl`), verified with
  `phase1_verify.py`, tiered with `phase1_cohort.sql` into
  `wcp_analysis.whole_class_cohort` and `data/whole_class_cohort.csv`:
  - A confirmed (LLM + history) 65 (9 from 2023); B history-only 27 (5);
    C LLM-only 46 (12); D disputed 42 (9).
  - Instructors edited the shared pages in 41 of 65 tier-A courses, vs 110 of
    510 non-whole-class labeled courses on their top pages.
  - The post-2023 whole-class sample is small (14 in A+B).
- 2026-09-29: Operator skipped the skim; core cohort = tiers A+B (92), tier C
  as sensitivity. Comparison set (`phase2_comparison_set.sql`,
  `wcp_analysis.comparison_set`): 365 courses — up to 3 same-instructor
  individual/small-group courses per cohort course (128 comparisons covering
  67 cohort courses) and 1 matched individual + 1 matched small-group course
  (same subject, start year +-1, active students within 1.5x; matches found
  for about half the cohort).
- Phase 2 non-LLM signals: `phase2_fetch.rb` saves per course-article
  bundles (revisions through +180 days with sha1/tags, wikitext at baseline /
  end / +180 days / current, LiftWing quality) for ~3,400 enwiki pages where
  the class added >= 200 characters; `phase2_metrics.py` computes survival,
  reverts, references, inline/banner cleanup tags, quality change and
  deletion; `phase3_compare.py` aggregates per course and compares groups,
  within instructor, and pre-2023 vs 2023+.
- 2026-09-29: Phase 2 fetch complete (3,403 enwiki course-article pages; 328
  courses with outcomes). First comparison (`phase3_compare.py`; outputs in
  `data/phase3_results_*.txt`):
  - Raw course-level gaps favor whole-class: fewer student revisions reverted
    (2.0% vs ~5%; by outsiders 1.0% vs ~3%), larger LiftWing quality gain
    (+1.2 vs +0.8), also within instructor (reverts -1.5 pp, quality +0.33).
  - Both gaps largely vanish when pages are compared at similar amounts of
    added text: whole-class pages get more words each (median 1,186 vs 742),
    and bigger contributions have fewer reverts and larger quality gains.
  - No detectable difference in survival (180 days or today), references per
    1,000 words, or cleanup tags added after the term.
  - 2023+ whole-class sample is 10-12 courses; no evidence either way on the
    AI-era hypothesis from these signals.
  Next: LLM-graded sourcing/claim-support pilot (50 items, blinded), which
  measures the hypothesis's core outcome directly.
- 2026-09-30: LLM grading pilot (`phase2_llm_items.py`, `phase2_grading_rubric.md`,
  `phase2_llm_analyze.py`; results in `data/phase2_llm/pilot_results.txt`).
  49 blinded items (10-13 per group x era cell, 500-4,000 words added, one page
  per course), 223 sampled cited claims.
  - Source retrieval is the bottleneck: 146 claims got source text (37 via the
    Wayback Machine), but graders could check only 91 — many "ok" fetches are
    JSTOR/publisher landing pages or excerpts that miss the relevant passage.
  - Sonnet vs Opus on 12 items: claim support agreement 86% (kappa 0.79);
    overall quality and tone always within 1 point; categorical flags 75-83%.
  - Early (underpowered) pattern: whole-class passages graded slightly lower
    overall (2.6 vs 3.0) with more unsourced and essay-like writing; no
    contradicted claims anywhere; not-supported claims rare (0-11% of
    checkable). Checkable claims per cell (15-27) are too few for support
    comparisons.
- 2026-09-30: Full LLM grading run (`data/phase2_llm_full/`, results in
  `results.txt`): 233 blinded items from 154 courses (whole-class 66 pre-2023 /
  17 from 2023; comparison 75 / 75; up to 3 pages per whole-class course, 2 per
  comparison course), 1,067 claims. Retrieval now adds OpenAlex open-access
  lookups, direct Wayback captures (throttled; web.archive.org rate-limits and
  temporarily blocked this machine) and ~8,000-character excerpts: 708 claims
  had source text, 459 were checkable.
  - Sonnet vs Opus on 19 items: claim support 90% agreement (kappa 0.83);
    quality and tone always within 1 point; essay-like only 58%.
  - Pre-2023 (45 vs 54 courses): whole-class claims less often fully
    supported (39% vs 56% of checkable; diff -18 pp [-33, -2]), but "at least
    partly supported" is about equal (90% vs 93%) and not-supported/
    contradicted is similar (10% vs 7%). Supported vs partial is also where
    the two graders disagree most, so treat this as weak. No difference in
    overall quality, tone, original research, essay-like or unsourced text.
  - 2023+ (10 vs 45 courses): no significant differences.
  - AI-style prose roughly doubles pre-2023 to 2023+ in both groups (0.27 ->
    0.55 comparison, 0.30 -> 0.71 whole-class): no sign that whole-class
    projects were protected.
- 2026-10-21: Raw dump deleted (README.md step 6). It had been kept in
  `data/`; the runbook now keeps dumps outside the repo. The `wcp_raw`
  database has not been dropped yet.

