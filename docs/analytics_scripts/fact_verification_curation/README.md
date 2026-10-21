# Fact Verification rollout curation

Scripts behind the Fall 2026 curation of the Fact Verification exercise's claim
pool, `config/claim_verification_rollout.yml`. They were used in three stages:

1. **Choosing the rollout articles** (summer 2026, shipped in #6983 on
   2026-08-06). The harvested pool was scored, 54 articles were reviewed by hand,
   and the 25 that passed became the rollout list.
2. **Giving the team's claim review its claim ids** (for #7028, merged
   2026-09-01). The team checked every claim in the rollout articles by hand,
   and the config's `excluded_claim_ids` is keyed by the ids these scripts
   produced.
3. **Comparing student answers with the team's** (2026-09-15, over the 1,146
   responses submitted from July 29).

## Where the data lives

Everything these scripts read or write lives in `data/` next to them, which
`.gitignore` covers: the worksheets, the shortlist, the rollout list and the
claim checks. Two kinds of file stay outside the repo altogether. The team's
review spreadsheet holds the reviewers' names and notes, and response exports
hold student writing. `compare_responses.py` looks for the spreadsheet in
`~/fact_verification_curation/` by default, and the response exports write to
`~` by default.

## Files

| File | What it does |
|---|---|
| `build_article_inventory.rb` | Scores every harvested article and writes the curation worksheets `data/fv_article_inventory.csv` (one row per article) and `data/fv_claim_detail.csv` (one row per claim, with the sentence and citation) |
| `source_access_domains.yml` | Editable host → access-tier map, plus weak-source hosts |
| `subject_disciplines.yml` | Editable course-subject → discipline bucket map |
| `build_rollout_list.rb` | Turns the passing verdicts in `data/fv_rollout_shortlist.csv` into the rollout list, `data/fv_rollout_list.csv` and `.yml` |
| `claim_ids.rb` | Paste into a production Rails console. Reproduces the viewer's annotation of every rollout revision and writes article, position, claim id, ref id and sentence to a CSV (default `~/fv_claim_ids.csv`) |
| `claim_ids_merge.py` | Run locally. Inserts a "Claim ID" column into the review spreadsheet from that CSV. Refuses to write if any row fails to resolve or an article's row count differs from its highlighted-claim count. Needs `openpyxl` |
| `export_responses.rb` | **Run on production.** Exports student exercise responses to CSV (default `~/fv_responses_<date>.csv`) |
| `export_responses_console.rb` | The same export, pasteable into a production Rails console |
| `compare_responses.py` | Joins that CSV to the review spreadsheet: agreement rates and mismatch hot spots. Needs `openpyxl` |

Regenerate the worksheets after editing either YAML:

```bash
bundle exec rails runner docs/analytics_scripts/fact_verification_curation/build_article_inventory.rb
```

Regenerate the rollout list after editing verdicts in the shortlist:

```bash
bundle exec rails runner docs/analytics_scripts/fact_verification_curation/build_rollout_list.rb
```

Related: `../fact_verification_results/` summarizes how students are answering,
and `../fact_verification_instrument/` exports responses with their claims and
sources for designing a source-verification instrument.

## What we selected for

1. **Checkable sources.** Most of an article's cited sources should be readable
   online without a university library proxy.
2. **Not obvious slop.** The exercise's point is to surface AI-added text that
   *looks* well-sourced and accurate but isn't actually supported by the cited
   source. Content that's visibly junk teaches the wrong lesson, because the
   student spots it without ever opening the citation.
3. **A spread across sciences, social sciences, and humanities.**

## Reading the access columns

Nothing in the worksheets has been fetched. Every access number is a **prior
based on the source's hostname**, so it ranks articles for hand-checking rather
than answering whether a given source is readable.

| Tier | Meaning |
|---|---|
| `open` | Known freely-readable host — PMC, PLOS, MDPI, arXiv, `.gov`, IGO sites, open news |
| `paywalled` | Known subscription publisher — Elsevier, JSTOR, Wiley, Springer, OUP … |
| `abstract_only` | Citation/abstract free, full text isn't — PubMed, Google Books, ResearchGate |
| `doi_redirect` | A bare `doi.org` link; real access is unknown until it resolves |
| `unclassified` | Ordinary web host, no prediction made. Usually readable — this is *not* a negative signal |
| `offline` | Harvested as an offline source (book, print) — a student can't check it at all |

Pool-wide: 23.1% open, 18.8% paywalled, 7.3% abstract-only, 15.0% DOI redirect,
20.6% unclassified, 15.1% offline.

`doi_redirect` is the biggest genuine unknown at 863 claims. Resolving those
DOIs (or checking them against Unpaywall) is the single highest-value follow-up
if the open-access pool turns out too thin.

## Reading the quality-heuristic columns

These are weak signals for triage, not verdicts — the slop call is a human one,
made by reading `fv_claim_detail.csv` and the linked diff.

- `refs_per_sentence`, `max_refs_one_sentence`, `citation_stuffing` — piling four
  or more refs on one sentence is a common LLM tell.
- `weak_source_claims` — citations to self-published author sites, IMDb,
  YouTube, Wikipedia itself, homework-help sites.
- `mean_sentence_chars`, `short_sentences`, `pct_short_sentences` — very short
  claims tend to be captions or list fragments, poor exercise material.
- `pct_sentences_with_number` — a rough proxy for concretely checkable
  assertions (dates, quantities) versus vague definitional prose.
- `max_fraction_ai_generated`, `max_ai_likelihood`, `predicted_llm`,
  `pangram_urls` — the Pangram detection signals from the originating alert.
- `chars_added_after_alert` — post-alert editing on the article. A large number
  may mean the AI text was cleaned up or reverted, which would leave nothing to
  verify. **Not yet checked against live article text.**

The reviewer columns (`topic_override`, `access_spot_check`, `content_quality`,
`include`, `reviewer_notes`) ship blank and are never written by the script, so
they survive a regeneration only if you keep your annotated copy separate.

## Verified source accessibility (candidate set only)

The hostname priors above were checked against reality for the 54 shortlisted
articles — all 451 distinct source URLs were actually fetched. DOIs went
through Unpaywall; everything else got one HTTP GET with the landing page
classified. Results are in `fv_rollout_shortlist.csv`.

| | share of 451 URLs |
|---|---|
| accessible | 73.4% |
| uncertain | 15.7% |
| likely paywalled | 9.3% |
| dead link | 1.6% |

**The hostname priors were far too pessimistic.** They implied ~19% paywalled
pool-wide; the measured rate on candidate sources is ~9%. Two reasons: bare
`doi.org` links resolve to open copies more often than not, and a large block
of "unclassified" long-tail hosts turned out to be ordinary readable pages.

Two adjustments were needed and are worth knowing about:

- **Bot-blocking is not a paywall.** 87 URLs returned a Cloudflare or
  rate-limit interstitial. Most were on hosts that are free to read in a
  browser — MDPI (fully open access), loc.gov, Chronicling America,
  congress.gov, britannica.com, theguardian.com. Counting those as inaccessible
  would badly understate the usable pool, so blocks on known-open hosts are
  scored accessible and blocks on known subscription publishers are scored
  paywalled.
- **Two soft edges remain.** JavaScript-only data browsers (ISTAT) and
  archive.org borrow-required items are scored `accessible` even though neither
  serves a plain readable document. Spot-check these before assigning them.

## The shortlist (`fv_rollout_shortlist.csv`)

54 articles were reviewed by hand — every flagged diff read, every source URL
fetched. Verdicts: 12 `strong_candidate`, 13 `usable`, 16 `weak`, 13 `slop`.

Selection criteria, in the order they matter:

1. **The claims must superficially look like good encyclopedia content.** Neutral,
   relevant, plausible, competently cited. If a student can tell something is
   wrong without opening a source, the article teaches the wrong lesson.
2. **Plenty of immediately-accessible sources.** `claims_free_source` is the
   headline number — claims verifiable right now with no library login.
3. **Some paywalled sources are fine.** Students reach JSTOR and Elsevier
   through their libraries, so `claims_paywalled_source` is reported but never
   penalized. Dead links and bare landing pages are the real defect.

Whether the edit was later reverted is **not** a criterion. The exercise shows
students the harvested claim and its citation; it does not need the text to
still be in the article. `text_still_live_pct` is retained for information only.

## The rollout list (`fv_rollout_list.csv` / `.yml`)

The `strong_candidate` and `usable` verdicts, ranked. **25 articles, one
revision each, 580 claims.**

| topic area | articles |
|---|---|
| sciences | 8 |
| social sciences | 7 |
| health | 6 |
| humanities | 4 |

Rows are keyed by `(article_id, mw_rev_id)` — the pair
`RelevantClaimRevisionsForCourse` groups claims by, so a row is exactly one
tile a student can pick.

**Four articles were flagged twice and only one revision of each ships.**
Community health centers, Extensive farming, Solar desalination and Curly Girl
Method each have a second reviewed, eligible revision that the rollout leaves
out; the revision with more claims wins, higher revision id breaking a tie.
That drops **85 claims**, 70 of them Extensive farming's near-identical second
edit. The excluded revisions are in `other_flagged_revisions` and are printed
at the end of a build. Shipping them is a one-line change — take every revision
per article instead of the first.

Ranking is verdict tier, then `pct_claims_free_source`. **Claim volume is
deliberately not part of the ranking** — a large pool doesn't make a better
exercise, and ranking on it buried good small articles.

Counts come from the database, not the worksheet, so the list can't drift from
the pool it describes; `build_rollout_list.rb` reports any mismatch instead of
absorbing it.

### From rollout list to live config

For the August rollout (#6983), `build_rollout_list.rb` also wrote
`config/claim_verification_rollout.yml`, which the application reads through
`ClaimVerification::RolloutList`. `RelevantClaimRevisionsForCourse` narrows
every one of its scopes to that list, so every course sees only those
articles. Subject-tag and subject prioritization still order the tiles; they
just can't reach outside the list. Emptying `revisions:` or deleting the config
file restores the full harvested pool.

The config has been curated by hand since the Fall 2026 claim review (#7028
and later): three articles were removed, and individual claims are excluded by
id. The script no longer writes it, since a re-run would have thrown that
curation away. Its outputs in `data/` show what the verdicts alone would
produce.

Two things to know about how the gate lands in front of a student:

- **`RelevantClaimRevisionsForCourse::DEFAULT_LIMIT` was raised from 12 to 25**
  so the whole list is reachable. Prioritization now only affects the *order*
  tiles appear in, not which ones a student can get to. The limit goes back to
  being a display cap once the gate comes off, so revisit it then.
- **The gate covers what is offered, not what is already taken.** An existing
  `VerificationClaimAssignment` on a now-excluded claim still resolves, and
  `take` does not re-check eligibility. Students mid-exercise keep their claim.

### Claim-level spot checks (`claim_checks/`)

Two articles were checked claim by claim — each cited source actually retrieved
and read against the sentence it supports. This is the only place in the
selection where a claim's *truth* was assessed rather than its surface quality.

| Article | Checked | supported | partially | not supported | contradicted | unavailable |
|---|---|---|---|---|---|---|
| Diseases of poverty | 10 of 12 | 2 | 6 | 2 | — | — |
| Honolulu Courthouse riot | 6 of 39 | — | 2 | 2 | 1 | 1 |

Both are `strong_candidate`s, and only 2 of 16 claims fully checked out. **That
is the exercise working, not a defect** — these articles were selected because
the AI text looks well-sourced, and the check confirms it mostly isn't. The
recurring pattern is a real, on-topic, readable source supporting a general
version of the sentence, with invented precision layered on top: a statistic
absent from the paper, a causal mechanism the source never states, a source
cited for the one term it never uses.

One case is worth designing around: a Honolulu claim that is *factually true*
but cited to a source that doesn't contain it. A rubric that only offers
"supported / not supported" can't express that.

`spot_check_verdicts` in the rollout CSV carries these counts; the columns are
blank for the other 23 articles, which means unchecked, not clean.

### Known caveats

- **`discipline` is derived from the course's subject, not the article's
  topic.** "Extensive farming" is tagged `humanities` because a Books course
  edited it. Use the blank `topic_override` column when balancing the mix.
  61 articles have no usable subject at all and land in `unclassified`.
- **No liveness check.** The pool was harvested 2026-06-26 from alerts up to
  2026-06-21. Whether the AI-added text still exists in the current revision of
  each article is unverified.
- **The pool was local, not a copy of production.** It was regenerated in a
  development database from the production alerts in the 2026-06-21 dump, which
  contained no `verification_claims` table. Claim ids in the worksheets are
  that database's, not production's.
- **The 54-article gate is obsolete and too narrow.** Those 54 were picked by
  requiring ≥5 open-access claims and ≥40% open, using hostname priors that
  later measurement showed were far too pessimistic — and paywalled sources
  turned out to be acceptable anyway. 414 articles were never reviewed, 154 of
  them with 10+ claims. Several large ones excluded purely on access grounds
  (Chemotherapy, Death anxiety, Disorders of diminished motivation) are likely
  fine. Re-run the gate on retrievability rather than open-access share before
  concluding the pool is exhausted.
- **`usable_claim_estimate` is blank for 20 rows.** Only the second review pass
  was asked for that count, so first-pass articles have no estimate. It is not
  a zero.

## Claim ids for the review spreadsheet

The team's spreadsheet identified each claim by article name and the "Claim X
of N" position the exercise viewer shows for it. That position is only the
claim's order among the highlighted sentences, so it shifts whenever a claim
leaves the pool and can't be used to exclude one. `claim_ids.rb` and
`claim_ids_merge.py` gave every spreadsheet row its production
`VerificationClaim` id, which is the key `excluded_claim_ids` in the rollout
config uses (#7028, 2026-09-01).

Run both again if the spreadsheet gains articles or claims that have no id yet.
For other per-claim work, `claim_ids.rb` shows how to get from what a student or
reviewer sees ("Claim 3 of 17") to a database id.

## Comparing student answers to the team's

The spreadsheet is the reference: the team hand-checked every claim being
served, so it is our best evidence of the "right" answer for each one. Comparing
student responses against it shows how often students reach the same conclusion,
and which claims they systematically get differently.

Export from production, then compare locally:

```bash
# on production
CAMPAIGN=fall_2026 bundle exec rails runner \
  docs/analytics_scripts/fact_verification_curation/export_responses.rb

# locally, against the exported CSV
python3 docs/analytics_scripts/fact_verification_curation/compare_responses.py \
  ~/fv_responses_2026-09-15.csv --served-only
```

It has to run on production because the join key is the claim id, and that is
production's `verification_claims.id` — the same ids `excluded_claim_ids` in
`config/claim_verification_rollout.yml` names. A development database has its
own harvest with its own ids and will not join to anything.

The comparison verifies that join rather than trusting it: it checks the article
title on every matched row against the spreadsheet's, and says so loudly if they
disagree, because a silent id-space mismatch would make every number it prints
meaningless.

Two things it deliberately does not decide on its own:

- **"Source good?" is scored against both source questions.** The exercise asks
  two — `source_appropriate` ("the right kind of source for this claim") and
  `meets_rs_policy` ("meets WP:RS") — and that one column could mean either.
  Both are reported, which also shows which one the team's judgement tracks.
- **Agreement is reported exactly and in binary.** Exact maps each team label to
  one student option. Binary collapses to the distinction the exercise exists to
  teach — fully supported or not — which is also well defined for the retired
  `mostly_*` verdicts, where an exact mapping would be invented.

Blank spreadsheet cells are dropped from denominators, not scored as
disagreements. Student hedges (`unsure`, `undetermined`, `depends_on_use`,
`context_dependent`) are counted and reported apart from agreement, since there
is no yes/no in them to compare.

(README written by Claude Code.)
