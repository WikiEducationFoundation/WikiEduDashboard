# Pangram 4.1 window splitting

Run on 2026-11-16 after one student peer review (rev 1385856331, Draft talk:Music
festival fashion) scored 40% AI as production extracted it (Pangram 4.1),
while trivially reformatted copies scored 100% AI and 100% human. Pangram returned
identical results on repeat calls of the same text, but window count and verdict moved
with a two-line header, the signature line and one `&amp;` entity. These
scripts test whether that instability is general.

All scoring used the `pangram-4` model, which answered as version 4.1 on every call.
The data (`data/`, git-ignored) holds study inputs and raw responses. Every text
is public on Wikipedia or comes from the detector comparison samples.

## Scripts

- `probe_variants.rb` (Rails runner): the ablation that started this. It scores eight
  formatting-only variants of the text production sent for rev 1385856331 (header, signature,
  `&amp;`, body only) with Pangram 4 or an Originality 5 model. The responses from
  2026-11-16 (Pangram) and 2026-11-17 (Originality) are in `data/probe_rev1385856331/`,
  saved under the earlier names `result_*.json` and `originality_<model>_*.json`.
- `build_inputs.rb` (Rails runner): study 1 picks 150 detector comparison units of
  300–1,500 words that Pangram 4.0 already scored (stored rows, 2026-09-05 to
  2026-10-12): 50 known-human, 50 AI that 4.0 scored as one window, 50 AI that 4.0
  split. Study 2 makes six one-change variants of 40 of them: a two-line header,
  a talk-page signature, `&amp;` or `&` for the " and " nearest the middle, blank
  lines collapsed, newlines removed.
- `collect_peer_reviews.rb` (Rails runner): study 3 collects student peer reviews
  written before ChatGPT. Each comes from the reviewer's last revision before
  2022-06-30 of a "User:Owner/Article/Reviewer Peer Review" page. The text is
  extracted with `GetRevisionPlaintext`, as production would extract it, and
  scored three ways: as extracted, with heading and label lines removed, and with
  HTML entities unescaped when there were any.
  It pauses between Wikipedia requests, because unthrottled requests were refused.
- `score_inputs.rb` (Rails runner): sends each input row to Pangram and saves the
  raw response to `data/results/<id>.json`. Resumable.
- `analyze.py`: prints the tables below. `python3 -I analyze.py data`
- `production_humanizer_alerts.rb`: paste into a production console. Read-only. It
  counts how many production 4.1 results reach alert level and how many of those
  rest on humanizer-flagged windows, and lists them with their alert ids.

## Findings (2026-11-16, 415 calls)

- **4.1 splits more than 4.0, without changing verdicts on clean texts.** On the same texts,
  AI texts that 4.0 split went from a median of 3 windows to 13, and 12 of 50
  known-human texts split where 4.0 split none. Labels barely moved. All 50 human
  texts stayed Human with no alert-level window. Under the production rule (any
  window above 0.9), the AI texts that 4.0 split went from 7/50 alerting to 48/50.
- **Trivial edits rarely change the verdict.** Across 215 variants, window counts
  often changed on AI texts that 4.0 split (60–90% per edit type), but labels changed in 2 cases and
  alerts in none. Human texts were unaffected. Windows with identical text kept
  their score in 99% of cases.
- **Pre-2022 peer reviews scored as human.** 21 reviews: all Human,
  no alert, under every variant. 8 of the 21 had HTML entities left escaped by
  `GetRevisionPlaintext`. Unescaping them changed nothing here.
- **The humanizer flag never fired on the study texts.** Across 1,969 windows the
  highest `humanizer_score` was 0.12. The rev 1385856331 windows scored 0.97–0.999,
  and its instability travels with the humanizer flag rather than with window
  splitting in general.
- **The flag fires often in production.** `production_humanizer_alerts.rb`, run on
  2026-11-16, showed that production checks moved from 4.0 to 4.1 on 2026-10-19 16:43 UTC. Of 7,853
  4.1 checks since then, 1,451 reached alert level (some window above 0.9), and 600 had a
  window with a humanizer score above 0.5. 307 alerts had a humanizer-flagged hot window, and in 252 every hot window was
  humanizer-flagged. These windows are not short: the median largest hot window was
  168 words. So the study corpus (pre-2023 human text and synthetic AI text) is missing
  whatever triggers the flag in current student writing, and those alerts can't be
  checked against known authorship.

- **The `&amp;` came from us.** `GetRevisionPlaintext` left HTML entities escaped. Fixed in
  the same PR as these scripts. On rev 1385856331, changing just that one entity took the
  production text from Mixed (39% AI, an alert) to Human (0%).
- **Originality 5.0 doesn't settle it** (2026-11-17, same eight variants). 5.0 said "mixed",
  50–70% AI, on every variant. 5.0 Max said mixed 45–65% with the header and "human" (7%) for
  the body alone, the reverse of Pangram's 100% AI. The passages Originality scored 1.00 are
  ones Pangram scored about 0, and the reverse.

Limits: 21 peer reviews, not the 50 intended; the page-id filter left too few
pre-cutoff pages in the first 8,000 search results. Known-human texts are
pre-2023 and may be in Pangram's training data. No current-term student text with
known authorship was available.

(README written by Claude Code.)
