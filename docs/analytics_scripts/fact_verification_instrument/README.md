# Fact Verification: source-verification instrument

`responses.rb` exports every Fact Verification exercise response with its claim
and cited source. Paste it into a production Rails console; it writes
`~/fv_responses.csv` (override with `FV_RESPONSES_CSV`).

It was written in October 2026 to pick candidate items for a short
source-verification instrument (pre/post, or post-only), then at the planning
stage. Joined by claim id to the team's verdicts in the Fall 2026 review
spreadsheet (see `../fact_verification_curation/`), it shows how often students
called a claim fully supported when the team did not, and what they pointed to
in the source when they did (`claim_location`).

The export identifies a response only by its course id, but the free-text
answers are student writing. Keep the CSV, and anything derived from it, outside
the repo.

(README written by Claude Code.)
