# WVS Northeastern AI-edits dataset

Builds a structured dataset of the lead-paragraph edits made on en.wikipedia
as part of the *WVS Northeastern University* AI-assistance research
experiment described at
<https://en.wikipedia.org/wiki/User:Rosiestep/WVS_Northeastern_University/Research>.

Each row of the final spreadsheet represents one article that was edited
with chatbot output during the experiment, and carries:

- the article title
- a link to the diff where the AI-assisted lead was added
- the full plaintext of the lead section *before* the edit
- the full plaintext of the lead section *after* the edit
- whether the AI output was accepted verbatim or edited before saving
- which of the six prompt variants was used

## Source inputs

| File | Source |
| ---- | ------ |
| `data/expected_titles.txt` | The researcher's list of 75 articles that were actually part of the experiment. Hand-maintained. |
| `data/2025 WVS NEU experiment.xlsx` | Per-article metadata spreadsheet supplied by the researcher: Edited/Verbatim status, prompt number, ORES scores, timing. |
| Rosiestep's en.wikipedia contributions | Queried live via the MediaWiki `usercontribs` API. |

## Pipeline

Each script writes one CSV that the next reads. All inputs and outputs
live in `data/`, which is gitignored: the scripts and this README are
committed, the data is not. To rebuild in a fresh checkout, put the two
hand-supplied inputs above into `data/` first.

```
fetch_contributions.rb  ->  data/contributions.csv          (all AI-tagged edits Rosiestep ever made)
curate.rb               ->  data/contributions.curated.csv  (filtered to the 75-article experiment list)
fetch_leads.rb          ->  data/leads.csv                  (adds lead_before / lead_after plaintext)
import_experiment.rb    ->  data/experiment.csv             (flattens the xlsx metadata sheet)
export_dataset.rb       ->  data/dataset.csv, dataset.tsv   (final spreadsheet, joined on title)
```

Run them in that order:

```sh
bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/fetch_contributions.rb
bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/curate.rb
bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/fetch_leads.rb
bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/import_experiment.rb
bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/export_dataset.rb
```

`fetch_contributions.rb` is the slow step (~3 minutes — it paginates
through Rosiestep's full contribution history, about 321 000 edits, looking
for the AI-assisted edit-summary pattern). The rest finish in seconds.

### What each step does

**`fetch_contributions.rb`** — queries MediaWiki's `usercontribs` API for
every edit by User:Rosiestep, filters comments matching
`/assisted by generative AI/i`, and writes `contributions.csv` with
`revid, parentid, title, timestamp, comment, diff_url`. Finds 78 edits
covering 77 unique articles.

**`curate.rb`** — reconciles the auto-detected 78 edits against
`expected_titles.txt` (the researcher's confirmed 75-article list). Drops
three edits that matched the AI-summary regex but weren't on the expected
list (see *Notes* below) and consolidates Ada L. Halstead's two
back-to-back edits into a single row spanning from the parent of the
first edit through the revid of the second. Also applies one historic-
to-current title rename (`Libbie Riley Baer` → `Libbie C. Riley Baer`).
Result: 74 rows covering 74 articles.

**`fetch_leads.rb`** — for each kept edit, calls MediaWiki's `parse` API
twice (once for the parent revision, once for the new revision) with
`section=0` to retrieve only the lead section. Strips the rendered HTML
down to prose: removes infobox tables, figures, images, citations, the
`{{Short description}}` hidden div, and "Cite error" messages the parser
emits when section=0 is rendered in isolation from `<references/>`. Adds
`lead_before` and `lead_after` columns.

**`import_experiment.rb`** — shells out to `libreoffice --headless` to
convert the xlsx to CSV (since no XLSX gem is in the project bundle),
then flattens the first sheet to `experiment.csv` with only the three
columns we need: `title`, `output` (Edited / Verbatim), `prompt`. Warns
on rows whose prompt number isn't an integer in 1–6.

**`export_dataset.rb`** — joins `leads.csv` and `experiment.csv` on
article title, applying the same rename mapping as `curate.rb`, and
writes the final `dataset.csv` and `dataset.tsv`. Columns:

```
title, diff_url, timestamp, revid, parentid, output, prompt,
comment, lead_before, lead_after
```

## Notes and caveats

- **Excluded from the expected list but found by the regex.** Three edits
  Rosiestep made with the AI-assisted summary were not on the
  researcher's 75-article list and are dropped by `curate.rb`:
  - *Mary Rankin Cranston* (2025-12-12) — two months after the main
    September–October experiment window, minor de-wikification rather
    than a lead expansion.
  - *Catharine Newsome Jewell* and *Candela Sierra* — both AI-tagged
    lead rewrites that are not on the researcher's list.

- **On the expected list but not found by the regex.** *Abigail Goodrich
  Whittelsey* is on the expected list of 75 but was saved with the edit
  summary `c/e` (copyedit) rather than the AI-assistance phrase, so the
  auto-fetch step doesn't pick it up. The final dataset therefore
  contains 74 articles, not 75. Adding it would require another manual
  override in `curate.rb`.

- **Ada L. Halstead two-edit consolidation.** Rosiestep saved the big
  AI-assisted lead expansion (rev 1314139080) and then six minutes later
  refined the opening sentence (rev 1314139788). `curate.rb` merges
  these: `parentid` is taken from the earlier edit and `revid` from the
  later, so `lead_before` / `lead_after` span both.

- **Libbie Baer rename.** The edit was saved when the article was at
  `Libbie Riley Baer`; it has since been moved to `Libbie C. Riley Baer`.
  The rename mapping lives in both `curate.rb` and `export_dataset.rb`.

- **Prompt-number anomalies.** A few prompt numbers in the xlsx aren't
  integers from 1 to 6, so they don't match the documented six prompts.
  `import_experiment.rb` warns about these; they're likely a typo or
  cell-formatting artifact and need a manual fix at the source.

- **Hand edits to the final `dataset.csv`.** The copy in `data/` differs
  from what `export_dataset.rb` produces in two cells (one `prompt`, one
  `diff_url`). `dataset.tsv` carries neither edit. Re-running
  `export_dataset.rb` overwrites both files and loses these edits. The
  details are in `data/HAND_EDITS.md`, which stays local with the data
  because they come from the researcher's unpublished spreadsheet.

- **No XLSX gem.** `import_experiment.rb` relies on the system
  `libreoffice` CLI for xlsx → CSV conversion. Picking up `roo` or a
  similar gem would avoid the dependency on LibreOffice being installed.

(README written by an AI coding agent; updated for the data/ layout by Claude Code.)
