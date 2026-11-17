# Article Audit: evaluation exports

`evaluate.rb` gathers Article Audits into files the team can review by
hand, to judge whether each check's findings are accurate and useful before
the feature goes further. It either runs new audits over a list of pages or
exports audits that have already run.

```bash
# Run a new audit of each URL in the file (one per line; # starts a comment)
URLS=~/audit_urls.txt bundle exec rails runner docs/analytics_scripts/article_audit/evaluate.rb

# Only some checks, eg to compare a prompt change without paying for the rest
URLS=~/audit_urls.txt CHECKS=tone,policy bundle exec rails runner docs/analytics_scripts/article_audit/evaluate.rb

# Export audits that already exist, without running anything
AUDIT_IDS=5,7,10 bundle exec rails runner docs/analytics_scripts/article_audit/evaluate.rb
```

A URL can be a page (its latest revision is audited), a permanent link or a
diff, as on the Article Audit page. Audits run one after another, in the
script's own process rather than through Sidekiq. Each one costs real API
credits: about $0.30 to $1.40 each in November 2026 trials, depending on the
article's length and how many sources it cites. The script prints each
audit's cost as it goes.

It writes three files to `OUT` (default `~/article_audit_eval/<timestamp>/`):

- `findings.csv`: one row per finding, from the latest run of each check.
  `title` and `explanation` come from LLM checks; checks written in code give a
  `code` and `details` instead. `accurate`, `useful` and `reviewer_notes` are
  blank columns for reviewers to fill in.
- `checks.csv`: one row per check per audit, with status, number of findings,
  tokens, cost, duration and any error. Use it to compare checks' cost and
  to spot ones that fail.
- `audits.json`: everything, including artifacts (the source table, proposed
  categories, citation verdicts and so on), for anything the CSVs leave out.

Costs are computed from the recorded tokens and the price table in the
script (`PRICES`), which needs updating if prices or models change. Checks
that don't call an LLM have no cost.

The output contains quotes from the audited pages, which are public wiki
text, but keep it outside the repo anyway, like other data.

It was written in November 2026, alongside the first version of Article
Audit, and tested then on the local development audits. It hasn't yet been
used for a full evaluation.

(README written by Claude Code.)
