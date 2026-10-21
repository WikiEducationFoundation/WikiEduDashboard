# Fact Verification rollout curation

Scripts behind the Fall 2026 curation of the Fact Verification exercise's claim
pool, `config/claim_verification_rollout.yml`.

## Claim ids for the review spreadsheet

Before the Fall 2026 rollout, the team checked every claim in the rollout
articles by hand, in a spreadsheet that identified each claim by article name
and the "Claim X of N" position the exercise viewer shows for it. That position
is only the claim's order among the highlighted sentences, so it shifts whenever
a claim leaves the pool and can't be used to exclude one. These two scripts gave
every spreadsheet row its production `VerificationClaim` id, which is the key
`excluded_claim_ids` in the rollout config uses (PR #7028, 2026-09-01).

| File | What it does |
|---|---|
| `claim_ids.rb` | Paste into a production Rails console. Reproduces the viewer's annotation of every rollout revision and writes article, position, claim id, ref id and sentence to a CSV (default `~/fv_claim_ids.csv`). |
| `claim_ids_merge.py` | Run locally. Inserts a "Claim ID" column into the spreadsheet from that CSV. Refuses to write if any row fails to resolve or an article's row count differs from its highlighted-claim count. Needs `openpyxl`. |

Run both again if the spreadsheet gains articles or claims that have no id yet.
For other per-claim work, `claim_ids.rb` shows how to get from what a student or
reviewer sees ("Claim 3 of 17") to a database id.

The spreadsheet and the CSV stay out of the repo: the spreadsheet holds the
reviewers' names and notes.

## Not here yet

The rollout config also points to this directory for how its 25 articles were
chosen: `build_rollout_list.rb` and a write-up of the selection. Those are in
another local checkout and haven't been committed. The script's input,
`fv_rollout_shortlist.csv`, is data and won't be.

(README written by Claude Code.)
