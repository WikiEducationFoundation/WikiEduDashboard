# Pangram preprocessing survey (Fall 2026)

Started 2026-11-17. Four suspected false positives on Outline sandboxes showed
non-prose in the text `GetRevisionPlaintext` sends to Pangram: bibliography
entries, list labels, headings, leftover preload instructions. On one
(rev 1381576051) removing the bibliography entries took the result from AI Detected
to Human Written; on another (rev 1381620281) removing non-prose raised the AI
share. This survey looks across the term's production checks for non-prose and
other screenable text before any preprocessing change.

Data lives outside the repo in `~/pangram_preprocessing_survey/` (the export holds
students' follow-up answers). Every scored text is public on Wikipedia.

## Scripts, in order

- `export_term_checks.rb`: paste into a production console. Read-only. Writes
  `~/pangram_checks_fall_2026.jsonl.gz`, one row per production Pangram check for
  Fall 2026 courses: page identity and type, detector summary, each window's
  offsets and scores, the public share link, and for alerts, the alert id, its
  resolved flag and the student's structured follow-up answers (no free text or
  usernames). Stored results hold no text; the share link returns the text Pangram
  scored. Run 2026-11-17: 14,074 checks, 7,601 of them Pangram 4.1.
- `fetch_texts.py`: picks a sample of 4.1 checks (per page type up to 40 alert-level
  and 20 others, plus every alert-level check whose student follow-up says false
  positive; 630 in all) and saves each share link's text and windows.
- `template_lines.rb` (Rails runner): renders the Dashboard.wikiedu.org preload
  templates as `GetRevisionPlaintext` would extract them, for line matching.
- `analyze.py`: classifies each line (prose, template, citation, URL, label,
  heading or fragment, signature, wiki UI messages) and relates kinds to hot
  windows (above 0.9, the alert threshold). Lines repeated on 5+ users' pages
  count as template text too.
- `build_ablation.py`, `score_ablation.rb`, `compare_ablation.py`: re-score
  alert-level texts with template lines or citation lines removed, plus unchanged
  texts as a drift baseline (64 Pangram calls, 2026-11-17).

## Findings (2026-11-17)

- **Blank lines don't matter.** Pangram collapses runs of blank lines before
  windowing; the text it stores and indexes windows against has none.
- **Template text is common but doesn't drive alerts.** Preload text makes up 2–9%
  of words on exercise pages and touches hot windows in most of their alerts, but
  removing it cleared 1 of 30 alerts (0 of 20 with student false-positive claims)
  and left the median AI fraction unchanged.
- **Citations cut both ways.** Removing citation lines cleared 5 of 24 alerts,
  mostly pages that were little but references, where Pangram had scored the
  references themselves at 1.0. On the rest it raised the AI fraction (13 up, 6
  down, median +0.08) and turned 10 Mixed results into AI: citations were scored
  Human and diluted the prose around them.
- **Re-scoring drift is small.** 10 unchanged texts: no alert cleared, AI fraction
  unchanged on 7 and within 0.10 on the rest.
- **Windows of pure non-prose are rare.** In 3 of 430 alert-level checks every hot
  window was mostly non-prose.
- Student false-positive claims (199 this term) come mostly from Evaluate, Outline
  and Choose exercises. Their hot windows are planning prose, not template text or
  citations, and preprocessing does not change those verdicts.

## Outcome

`NonProseLineFilter` (`lib/ai/non_prose_line_filter.rb`), applied in
`GetRevisionPlaintext`, drops citation lines, bare URLs, preload template
instruction lines and bare signature lines; `GetRevisionPlaintext` also drops the
DiscussionTools section bar. On the 630 sampled texts it removes 6% of words. In
spot checks of each rule no prose line was dropped as a citation; 4 lines (383
words) held a student's annotation on the same line as a citation and are dropped
whole. 12 sampled checks would fall under the 500-character minimum and not be
sent, 5 of them alert-level.

(README written by Claude Code.)
