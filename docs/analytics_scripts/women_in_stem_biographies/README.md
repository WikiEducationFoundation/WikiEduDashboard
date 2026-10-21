# Women in STEM biographies edited by students

A pipeline that finds biographies of women in STEM among the English Wikipedia
articles Wiki Ed students edited in the summer 2025, fall 2025 and spring 2026
terms. It counts the articles and students involved, broken down by how much
the students added, and how often the articles have been read since. It was
run on 2026-05-19.

"STEM" comes in three nested tiers, so the counts can be quoted at whichever
breadth a question needs:

1. core STEM: natural sciences, mathematics, engineering, computing
2. tier 1 plus medicine and health
3. tier 2 plus the social sciences

## Running it

The scripts are plain Python 3 (standard library only) and run in order. The
network steps cache their responses, so an interrupted run picks up where it
stopped instead of starting over.

| Step | Script | What it does |
|---|---|---|
| 1 | `consolidate.py` | Merges the three terms' campaign article CSVs into one row per English Wikipedia mainspace title, with its students, earliest course start date and totals |
| 2 | `gather_signals.py` | **Network.** Fetches each title's Wikidata item, short description, categories and lead paragraph from English Wikipedia, plus instance-of, sex or gender, and occupation from Wikidata |
| 3 | `classify_women_bios.py` | Combines those signals to decide whether each article is a biography of a woman and which tier it falls in. Confident cases are decided automatically and ambiguous ones go to a review list. A random 100 of the exclusions are written out for a spot-check |
| 3a | `_write_review_decisions.py` | One-off: records the decisions for the review list, made by Claude reading each row's evidence. They're hardcoded in the script, each with a note on why |
| 3b | `merge_classifications.py` | Merges the automatic and reviewed rows into the final list |
| 4 | `add_pageviews.py` | **Network.** Pageviews per article since its earliest course start date |
| 4′ | `add_pageviews_first_student_edit.py` | **Network.** The same, counted from the first edit by one of the article's students (the window the Dashboard itself uses) |
| 5 | `summary.py` | Prints the headline numbers per tier and per size of student contribution. Pass the step 4′ CSV as an argument to use that window |

Words are estimated from characters added the way `lib/word_count.rb` does
it.

## Data

Inputs, outputs and the response cache live in `data/`, which `.gitignore`
covers. The inputs are the Dashboard's campaign article CSVs for the
`summer_2025`, `fall_2025` and `spring_2026` campaigns, downloaded on
2026-05-19 as `<term>-campaign_articles-2026-05-19.csv`. To re-run from
scratch, put fresh downloads there and update `INPUT_TEMPLATE` in
`consolidate.py`.

`data/` also holds two kinds of file the scripts don't touch: the campaigns'
student CSVs, which were downloaded alongside but never read, and
`core_stem_500words.csv` (2026-06-05). That one lists the tier 1 articles where
students added 500 words or more, but no script here produces it.

(README written by Claude Code.)
